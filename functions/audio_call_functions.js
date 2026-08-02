"use strict";

const admin = require("firebase-admin");
const functionsV1 = require("firebase-functions/v1");
const { logger } = require("firebase-functions");
const { defineSecret } = require("firebase-functions/params");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { RtcRole, RtcTokenBuilder } = require("agora-token");

const {
  agoraUidFromFirebaseUid,
  channelNameForCall,
  createCallId,
  isTerminalCallStatus,
  normalizeUid,
  participantRole,
  pointerAvailable,
  safeDisplayName,
  validCallId,
} = require("./audio_call_logic");
const {
  readPremiumEntitlement,
  requirePremiumEntitlement,
} = require("./premium_entitlement_functions");
const { tokenDocumentId } = require("./notification_logic");

const REGION = "asia-south1";
const RING_TIMEOUT_SECONDS = 60;
const CALL_MAX_SECONDS = 2 * 60 * 60;
const RTC_TOKEN_SECONDS = 2 * 60 * 60;
const CLEANUP_LIMIT = 100;
const MULTICAST_LIMIT = 500;

const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

const db = admin.firestore();
const messaging = admin.messaging();

function requireAuthenticatedUid(request) {
  const uid = normalizeUid(request.auth && request.auth.uid);
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function callRef(callId) {
  return db.collection("audioCalls").doc(callId);
}

function activePointerRef(uid) {
  return db.collection("activeAudioCalls").doc(uid);
}

function requireCallId(request) {
  const callId = request.data && request.data.callId;
  if (!validCallId(callId)) {
    throw new HttpsError("invalid-argument", "Invalid audio call.");
  }
  return callId;
}

async function requireActiveProfile(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  const data = snapshot.exists ? snapshot.data() : null;
  if (!data || data.isSuspended === true || !safeDisplayName(data.nickname)) {
    throw new HttpsError("failed-precondition", "An active NearMeU profile is required.");
  }
  return snapshot;
}

async function blockedEitherWay(firstUid, secondUid) {
  const [firstBlocksSecond, secondBlocksFirst] = await Promise.all([
    db.collection("users").doc(firstUid).collection("blocks").doc(secondUid).get(),
    db.collection("users").doc(secondUid).collection("blocks").doc(firstUid).get(),
  ]);
  return firstBlocksSecond.exists || secondBlocksFirst.exists;
}

function agoraCredentials() {
  const appId = AGORA_APP_ID.value().trim();
  const appCertificate = AGORA_APP_CERTIFICATE.value().trim();
  if (!appId || !appCertificate) {
    throw new HttpsError(
      "failed-precondition",
      "Audio calling is not configured yet.",
      { reason: "agora-not-configured" },
    );
  }
  return { appId, appCertificate };
}

function issueRtcAccess(uid, channelName) {
  const { appId, appCertificate } = agoraCredentials();
  const agoraUid = agoraUidFromFirebaseUid(uid);
  const privilegeExpireTs = Math.floor(Date.now() / 1000) + RTC_TOKEN_SECONDS;
  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    agoraUid,
    RtcRole.PUBLISHER,
    privilegeExpireTs,
  );
  return {
    appId,
    channelName,
    agoraUid,
    token,
    tokenExpiresAtMillis: privilegeExpireTs * 1000,
  };
}

function publicCallState(callId, data, viewerUid, includeRtcAccess = false) {
  const role = participantRole(data, viewerUid);
  if (!role) throw new HttpsError("permission-denied", "Audio call is unavailable.");
  const otherUid = role === "caller" ? data.calleeUid : data.callerUid;
  const otherName = role === "caller" ? data.calleeName : data.callerName;
  const response = {
    callId,
    role,
    status: data.status,
    otherUserId: otherUid,
    otherUserName: safeDisplayName(otherName),
    createdAtMillis: data.createdAtMillis || null,
    acceptedAtMillis: data.acceptedAtMillis || null,
    endedAtMillis: data.endedAtMillis || null,
    ringExpiresAtMillis: data.ringExpiresAtMillis || null,
    expiresAtMillis: data.expiresAtMillis || null,
  };
  if (includeRtcAccess && (data.status === "ringing" || data.status === "accepted")) {
    Object.assign(response, issueRtcAccess(viewerUid, data.channelName));
  }
  return response;
}

async function deleteMatchingPointers(transaction, data, callId) {
  const refs = [activePointerRef(data.callerUid), activePointerRef(data.calleeUid)];
  const snapshots = await Promise.all(refs.map((ref) => transaction.get(ref)));
  snapshots.forEach((snapshot, index) => {
    if (snapshot.exists && snapshot.get("callId") === callId) {
      transaction.delete(refs[index]);
    }
  });
}

async function finishCall(callId, status, endedByUid = null) {
  const ref = callRef(callId);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return null;
    const data = snapshot.data();
    if (isTerminalCallStatus(data.status)) return data;
    const nowMillis = Date.now();
    transaction.update(ref, {
      status,
      endedByUid,
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedAtMillis: nowMillis,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await deleteMatchingPointers(transaction, data, callId);
    return { ...data, status, endedByUid, endedAtMillis: nowMillis };
  });
}

async function sendIncomingCallPush(callId, callerName, calleeUid) {
  const devices = await db
    .collection("privateProfiles")
    .doc(calleeUid)
    .collection("devices")
    .orderBy("updatedAt", "desc")
    .limit(500)
    .get();
  if (devices.empty) return 0;

  const unique = [];
  const seen = new Set();
  for (const device of devices.docs) {
    const token = device.get("token");
    if (typeof token !== "string" || !token || seen.has(token)) continue;
    seen.add(token);
    unique.push({ snapshot: device, token });
  }

  let sent = 0;
  for (let start = 0; start < unique.length; start += MULTICAST_LIMIT) {
    const chunk = unique.slice(start, start + MULTICAST_LIMIT);
    const response = await messaging.sendEachForMulticast({
      tokens: chunk.map((item) => item.token),
      notification: {
        title: "Incoming NearMeU audio call",
        body: `${safeDisplayName(callerName)} is calling you`,
      },
      data: {
        type: "audio_call",
        callId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nearmeu_calls",
          priority: "max",
          sound: "default",
          tag: `audio-call-${callId}`,
        },
      },
    });
    sent += response.successCount;

    const cleanup = db.batch();
    let cleanupWrites = 0;
    response.responses.forEach((item, index) => {
      if (item.success) return;
      const code = item.error && item.error.code;
      if (code !== "messaging/registration-token-not-registered" &&
          code !== "messaging/invalid-registration-token") {
        return;
      }
      const invalid = chunk[index];
      if (!invalid) return;
      cleanup.delete(invalid.snapshot.ref);
      cleanup.delete(db.collection("deviceTokenOwners").doc(tokenDocumentId(invalid.token)));
      cleanupWrites += 2;
    });
    if (cleanupWrites > 0) await cleanup.commit();
  }
  return sent;
}

exports.startAudioCall = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) => {
    const callerUid = requireAuthenticatedUid(request);
    const calleeUid = normalizeUid(request.data && request.data.calleeUid);
    if (!calleeUid || calleeUid === callerUid) {
      throw new HttpsError("invalid-argument", "Choose another NearMeU user to call.");
    }

    const [callerProfile, calleeProfile, entitlement, blocked] = await Promise.all([
      requireActiveProfile(callerUid),
      requireActiveProfile(calleeUid),
      readPremiumEntitlement(callerUid),
      blockedEitherWay(callerUid, calleeUid),
    ]);
    requirePremiumEntitlement(entitlement, "audio-call-initiation");
    if (blocked) throw new HttpsError("not-found", "This user is unavailable for calls.");

    const callId = createCallId();
    const channelName = channelNameForCall(callId);
    const nowMillis = Date.now();
    const ringExpiresAtMillis = nowMillis + RING_TIMEOUT_SECONDS * 1000;
    const expiresAtMillis = nowMillis + CALL_MAX_SECONDS * 1000;
    const callerName = safeDisplayName(callerProfile.get("nickname"));
    const calleeName = safeDisplayName(calleeProfile.get("nickname"));
    const ref = callRef(callId);
    const callerPointer = activePointerRef(callerUid);
    const calleePointer = activePointerRef(calleeUid);

    await db.runTransaction(async (transaction) => {
      const [callerActive, calleeActive] = await Promise.all([
        transaction.get(callerPointer),
        transaction.get(calleePointer),
      ]);
      if (!pointerAvailable(callerActive.exists ? callerActive.data() : null, nowMillis) ||
          !pointerAvailable(calleeActive.exists ? calleeActive.data() : null, nowMillis)) {
        throw new HttpsError("resource-exhausted", "One of you is already in another call.");
      }

      const callData = {
        schemaVersion: 1,
        type: "audio",
        callerUid,
        calleeUid,
        callerName,
        calleeName,
        participants: [callerUid, calleeUid].sort(),
        channelName,
        status: "ringing",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAtMillis: nowMillis,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ringExpiresAtMillis,
        expiresAtMillis,
      };
      transaction.create(ref, callData);
      const pointerData = { callId, expiresAtMillis, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
      transaction.set(callerPointer, pointerData);
      transaction.set(calleePointer, pointerData);
    });

    let pushCount = 0;
    try {
      pushCount = await sendIncomingCallPush(callId, callerName, calleeUid);
    } catch (error) {
      logger.error("Audio call invite push failed", { callId, calleeUid, error });
    }

    const created = await ref.get();
    return {
      ...publicCallState(callId, created.data(), callerUid, true),
      invitePushCount: pushCount,
    };
  },
);

exports.getAudioCall = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const callId = requireCallId(request);
    const snapshot = await callRef(callId).get();
    if (!snapshot.exists) throw new HttpsError("not-found", "Audio call is unavailable.");
    const data = snapshot.data();
    const role = participantRole(data, uid);
    if (!role) throw new HttpsError("permission-denied", "Audio call is unavailable.");

    const otherUid = role === "caller" ? data.calleeUid : data.callerUid;
    const [viewerProfile, otherProfile, blocked] = await Promise.all([
      requireActiveProfile(uid),
      requireActiveProfile(otherUid),
      blockedEitherWay(uid, otherUid),
    ]);
    if (!viewerProfile.exists || !otherProfile.exists || blocked) {
      await finishCall(callId, "ended", uid);
      throw new HttpsError("not-found", "Audio call is unavailable.");
    }

    if (data.status === "ringing" && Date.now() >= Number(data.ringExpiresAtMillis || 0)) {
      const finished = await finishCall(callId, "missed", null);
      return publicCallState(callId, finished, uid, false);
    }
    if (!isTerminalCallStatus(data.status) && Date.now() >= Number(data.expiresAtMillis || 0)) {
      const finished = await finishCall(callId, "expired", null);
      return publicCallState(callId, finished, uid, false);
    }

    const includeRtc = data.status === "accepted" || (role === "caller" && data.status === "ringing");
    return publicCallState(callId, data, uid, includeRtc);
  },
);

exports.respondAudioCall = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const callId = requireCallId(request);
    const accept = request.data && request.data.accept === true;
    const ref = callRef(callId);

    const updated = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw new HttpsError("not-found", "Audio call is unavailable.");
      const data = snapshot.data();
      if (data.calleeUid !== uid) {
        throw new HttpsError("permission-denied", "Only the receiver can answer this call.");
      }
      if (data.status !== "ringing") return data;
      const nowMillis = Date.now();
      if (nowMillis >= Number(data.ringExpiresAtMillis || 0)) {
        transaction.update(ref, {
          status: "missed",
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          endedAtMillis: nowMillis,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await deleteMatchingPointers(transaction, data, callId);
        return { ...data, status: "missed", endedAtMillis: nowMillis };
      }
      if (!accept) {
        transaction.update(ref, {
          status: "declined",
          endedByUid: uid,
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          endedAtMillis: nowMillis,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await deleteMatchingPointers(transaction, data, callId);
        return { ...data, status: "declined", endedByUid: uid, endedAtMillis: nowMillis };
      }
      transaction.update(ref, {
        status: "accepted",
        acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
        acceptedAtMillis: nowMillis,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { ...data, status: "accepted", acceptedAtMillis: nowMillis };
    });

    if (updated.status === "accepted") {
      const blocked = await blockedEitherWay(updated.callerUid, updated.calleeUid);
      if (blocked) {
        await finishCall(callId, "ended", uid);
        throw new HttpsError("not-found", "Audio call is unavailable.");
      }
    }
    return publicCallState(callId, updated, uid, updated.status === "accepted");
  },
);

exports.endAudioCall = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const callId = requireCallId(request);
    const snapshot = await callRef(callId).get();
    if (!snapshot.exists) return { success: true, status: "ended" };
    const data = snapshot.data();
    if (!participantRole(data, uid)) {
      throw new HttpsError("permission-denied", "Audio call is unavailable.");
    }
    const status = data.status === "ringing" && data.callerUid === uid ? "ended" : "ended";
    const finished = await finishCall(callId, status, uid);
    return { success: true, status: finished ? finished.status : status };
  },
);

exports.expireStaleAudioCalls = onSchedule(
  {
    schedule: "every 5 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    const nowMillis = Date.now();
    const snapshot = await db
      .collection("audioCalls")
      .where("expiresAtMillis", "<=", nowMillis)
      .limit(CLEANUP_LIMIT)
      .get();
    for (const document of snapshot.docs) {
      const data = document.data();
      if (isTerminalCallStatus(data.status)) continue;
      await finishCall(document.id, data.status === "ringing" ? "missed" : "expired", null);
    }
  },
);

exports.purgeAudioCallOnAuthDelete = functionsV1
  .region(REGION)
  .auth.user()
  .onDelete(async (user) => {
    const pointer = await activePointerRef(user.uid).get();
    const callId = pointer.exists ? pointer.get("callId") : null;
    if (validCallId(callId)) {
      await finishCall(callId, "ended", user.uid).catch(() => {});
    }
    await activePointerRef(user.uid).delete().catch(() => {});
  });
