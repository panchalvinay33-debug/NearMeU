"use strict";

const admin = require("firebase-admin");
const { defineSecret } = require("firebase-functions/params");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { RtcRole, RtcTokenBuilder } = require("agora-token");

const {
  agoraUidFromFirebaseUid,
  channelNameForCall,
  isTerminalStatus,
  normalizeUid,
  participantRole,
  validCallId,
} = require("./audio_call_r2_logic");

const db = admin.firestore();
const REGION = "asia-south1";
const RTC_TOKEN_SECONDS = 2 * 60 * 60;
const AGORA_CREDENTIAL_PATTERN = /^[a-fA-F0-9]{32}$/;

const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

function requireAuthenticatedUid(request) {
  const uid = normalizeUid(request.auth && request.auth.uid);
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function requireCallId(request) {
  const callId = request.data && request.data.callId;
  if (!validCallId(callId)) {
    throw new HttpsError("invalid-argument", "Invalid audio call.");
  }
  return callId;
}

function readAgoraCredentials() {
  const appId = String(AGORA_APP_ID.value() || "").trim();
  const appCertificate = String(AGORA_APP_CERTIFICATE.value() || "").trim();
  if (
    !AGORA_CREDENTIAL_PATTERN.test(appId) ||
    !AGORA_CREDENTIAL_PATTERN.test(appCertificate)
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Audio calling configuration is invalid.",
      { reason: "agora-credentials-invalid" },
    );
  }
  return { appId, appCertificate };
}

async function requireActiveProfile(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  const data = snapshot.exists ? snapshot.data() : null;
  if (!data || data.isSuspended === true) {
    throw new HttpsError("failed-precondition", "An active NearMeU profile is required.");
  }
}

async function blockedEitherWay(firstUid, secondUid) {
  const [firstBlocksSecond, secondBlocksFirst] = await Promise.all([
    db.collection("users").doc(firstUid).collection("blocks").doc(secondUid).get(),
    db.collection("users").doc(secondUid).collection("blocks").doc(firstUid).get(),
  ]);
  return firstBlocksSecond.exists || secondBlocksFirst.exists;
}

exports.getAudioRtcAccessR2 = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const callId = requireCallId(request);
    const snapshot = await db.collection("audioCallsR2").doc(callId).get();
    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Audio call is unavailable.");
    }

    const call = snapshot.data();
    const role = participantRole(call, uid);
    if (!role) {
      throw new HttpsError("permission-denied", "Audio call is unavailable.");
    }
    if (isTerminalStatus(call.status)) {
      throw new HttpsError("failed-precondition", "This audio call has ended.");
    }
    if (call.status !== "ringing" && call.status !== "accepted") {
      throw new HttpsError("failed-precondition", "Audio call is unavailable.");
    }
    if (role === "callee" && call.status !== "accepted") {
      throw new HttpsError(
        "failed-precondition",
        "Accept the call before joining audio.",
      );
    }

    const otherUid = role === "caller" ? call.calleeUid : call.callerUid;
    await Promise.all([requireActiveProfile(uid), requireActiveProfile(otherUid)]);
    if (await blockedEitherWay(uid, otherUid)) {
      throw new HttpsError("not-found", "Audio call is unavailable.");
    }

    const nowMillis = Date.now();
    if (
      call.status === "ringing" &&
      nowMillis >= Number(call.ringExpiresAtMillis || 0)
    ) {
      throw new HttpsError("failed-precondition", "This call is no longer ringing.");
    }
    if (nowMillis >= Number(call.expiresAtMillis || 0)) {
      throw new HttpsError("failed-precondition", "This audio call has expired.");
    }

    const { appId, appCertificate } = readAgoraCredentials();
    const channelName = channelNameForCall(callId);
    const agoraUid = agoraUidFromFirebaseUid(uid);
    const expiresAtSeconds = Math.floor(nowMillis / 1000) + RTC_TOKEN_SECONDS;
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      agoraUid,
      RtcRole.PUBLISHER,
      expiresAtSeconds,
      expiresAtSeconds,
    );
    if (typeof token !== "string" || token.length < 20) {
      throw new HttpsError(
        "internal",
        "Audio access could not be created.",
        { reason: "agora-token-empty" },
      );
    }

    return {
      callId,
      role,
      appId,
      channelName,
      agoraUid,
      token,
      tokenExpiresAtMillis: expiresAtSeconds * 1000,
    };
  },
);
