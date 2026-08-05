"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const {
  normalizeUid,
  participantRole,
  safeDisplayName,
  validCallId,
} = require("./audio_call_r2_logic");

const db = admin.firestore();
const REGION = "asia-south1";

function authenticatedUid(request) {
  const uid = normalizeUid(request.auth && request.auth.uid);
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

exports.getIncomingAudioCallR2 = onCall(
  { region: REGION, timeoutSeconds: 15, memory: "256MiB" },
  async (request) => {
    const uid = authenticatedUid(request);
    const pointer = await db.collection("activeAudioCallsR2").doc(uid).get();
    if (!pointer.exists) return null;

    const callId = pointer.get("callId");
    if (!validCallId(callId)) return null;

    const snapshot = await db.collection("audioCallsR2").doc(callId).get();
    if (!snapshot.exists) return null;
    const call = snapshot.data();
    const role = participantRole(call, uid);
    const nowMillis = Date.now();

    if (
      role !== "callee" ||
      call.status !== "ringing" ||
      nowMillis >= Number(call.ringExpiresAtMillis || 0)
    ) {
      return null;
    }

    return {
      callId,
      callerUid: call.callerUid,
      callerName: safeDisplayName(call.callerName),
      ringExpiresAtMillis: call.ringExpiresAtMillis || null,
    };
  },
);
