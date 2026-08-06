"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { defineSecret } = require("firebase-functions/params");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { RtcTokenBuilder, RtcRole } = require("agora-token");

const db = admin.firestore();
const messaging = admin.messaging();
const REGION = "asia-south1";
const CALL_RING_SECONDS = 45;
const RTC_TOKEN_SECONDS = 15 * 60;
const HISTORY_LIMIT = 50;
const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

function requireUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function requireString(value, name, maximum = 256) {
  const text = typeof value === "string" ? value.trim() : "";
  if (!text || text.length > maximum) {
    throw new HttpsError("invalid-argument", `${name} is invalid.`);
  }
  return text;
}

function userRef(uid) {
  return db.collection("users").doc(uid);
}

function activeRef(uid) {
  return db.collection("activeAudioCallUsers").doc(uid);
}

function callRef(callId) {
  return db.collection("audioCalls").doc(callId);
}

async function assertCallablePair(callerId, calleeId) {
  if (callerId === calleeId) {
    throw new HttpsError("invalid-argument", "You cannot call yourself.");
  }
  const [caller, callee, callerBlocked, calleeBlocked] = await db.getAll(
    userRef(callerId),
    userRef(calleeId),
    userRef(callerId).collection("blocks").doc(calleeId),
    userRef(calleeId).collection("blocks").doc(callerId),
  );
  if (!caller.exists || caller.get("isSuspended") === true) {
    throw new HttpsError("failed-precondition", "Your profile is not active.");
  }
  if (!callee.exists || callee.get("isSuspended") === true) {
    throw new HttpsError("failed-precondition", "This user is not available.");
  }
  if (callerBlocked.exists || calleeBlocked.exists) {
    throw new HttpsError("permission-denied", "Calling is unavailable for this chat.");
  }
  return { caller, callee };
}

function buildRtcCredentials(uid, channelName) {
  const appId = AGORA_APP_ID.value().trim();
  const certificate = AGORA_APP_CERTIFICATE.value().trim();
  if (!appId || !certificate) {
    throw new HttpsError("failed-precondition", "Calling service is not configured.");
  }
  const token = RtcTokenBuilder.buildTokenWithUserAccount(
    appId,
    certificate,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    RTC_TOKEN_SECONDS,
    RTC_TOKEN_SECONDS,
  );
  return {
    appId,
    token,
    userAccount: uid,
    tokenExpiresInSeconds: RTC_TOKEN_SECONDS,
  };
}

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
}

function sanitizedCall(snapshot) {
  if (!snapshot || !snapshot.exists) return null;
  const data = snapshot.data() || {};
  return {
    callId: snapshot.id,
    callerId: data.callerId || "",
    calleeId: data.calleeId || "",
    callerName: data.callerName || "NearMeU User",
    calleeName: data.calleeName || "NearMeU User",
    status: data.status || "unknown",
    channelName: data.channelName || "",
    createdAtMs: timestampMillis(data.createdAt),
    answeredAtMs: timestampMillis(data.answeredAt),
    endedAtMs: timestampMillis(data.endedAt),
    expiresAtMs: timestampMillis(data.expiresAt),
    endedBy: data.endedBy || null,
    endReason: data.endReason || null,
  };
}

async function clearActiveUsers(transaction, callData, callId) {
  for (const uid of [callData.callerId, callData.calleeId]) {
    if (!uid) continue;
    const ref = activeRef(uid);
    const active = await transaction.get(ref);
    if (active.exists && active.get("callId") === callId) {
      transaction.delete(ref);
    }
  }
}

async function sendIncomingCallPush({ calleeId, callId, callerName }) {
  const devices = await db
    .collection("privateProfiles")
    .doc(calleeId)
    .collection("devices")
    .orderBy("updatedAt", "desc")
    .limit(20)
    .get();
  const tokens = [...new Set(devices.docs.map((d) => d.get("token")).filter((x) => typeof x === "string" && x))];
  if (!tokens.length) return;
  await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: "Incoming audio call",
      body: `${callerName || "NearMeU User"} is calling you`,
    },
    data: {
      type: "audio_call",
      callId,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "nearmeu_calls",
        sound: "default",
        tag: `audio_call_${callId}`,
      },
    },
  });
}

exports.startAudioCall = onCall(
  { region: REGION, secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE] },
  async (request) => {
    const callerId = requireUid(request);
    const calleeId = requireString(request.data && request.data.calleeId, "calleeId");
    const { caller, callee } = await assertCallablePair(callerId, calleeId);
    const newCallRef = db.collection("audioCalls").doc();
    const callId = newCallRef.id;
    const channelName = `nmu_${callId}`;
    const callerName = String(caller.get("nickname") || "NearMeU User").slice(0, 30);
    const calleeName = String(callee.get("nickname") || "NearMeU User").slice(0, 30);
    const now = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + CALL_RING_SECONDS * 1000);

    await db.runTransaction(async (transaction) => {
      const [callerActive, calleeActive] = await Promise.all([
        transaction.get(activeRef(callerId)),
        transaction.get(activeRef(calleeId)),
      ]);
      if (callerActive.exists || calleeActive.exists) {
        throw new HttpsError("resource-exhausted", "One of the users is already in another call.");
      }
      transaction.create(newCallRef, {
        callerId,
        calleeId,
        callerName,
        calleeName,
        channelName,
        status: "ringing",
        createdAt: now,
        expiresAt,
        answeredAt: null,
        endedAt: null,
        endedBy: null,
        endReason: null,
      });
      transaction.create(activeRef(callerId), { callId, role: "caller", updatedAt: now });
      transaction.create(activeRef(calleeId), { callId, role: "callee", updatedAt: now });
    });

    await sendIncomingCallPush({ calleeId, callId, callerName }).catch((error) => {
      logger.warn("Incoming call push failed", { callId, calleeId, error });
    });

    return {
      success: true,
      call: sanitizedCall(await newCallRef.get()),
      rtc: buildRtcCredentials(callerId, channelName),
    };
  },
);

exports.respondAudioCall = onCall(
  { region: REGION, secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE] },
  async (request) => {
    const uid = requireUid(request);
    const callId = requireString(request.data && request.data.callId, "callId");
    const accept = request.data && request.data.accept === true;
    const ref = callRef(callId);
    let channelName = "";
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw new HttpsError("not-found", "Call not found.");
      const data = snapshot.data();
      if (data.calleeId !== uid) throw new HttpsError("permission-denied", "Only the receiver can answer this call.");
      if (data.status !== "ringing") throw new HttpsError("failed-precondition", "This call is no longer ringing.");
      if (data.expiresAt && data.expiresAt.toMillis() <= Date.now()) {
        await clearActiveUsers(transaction, data, callId);
        transaction.update(ref, {
          status: "missed",
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          endReason: "ring-timeout",
        });
        throw new HttpsError("deadline-exceeded", "This call has expired.");
      }
      channelName = data.channelName;
      if (accept) {
        transaction.update(ref, {
          status: "connected",
          answeredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await clearActiveUsers(transaction, data, callId);
        transaction.update(ref, {
          status: "rejected",
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          endedBy: uid,
          endReason: "rejected",
        });
      }
    });
    const latest = await ref.get();
    return {
      success: true,
      call: sanitizedCall(latest),
      rtc: accept ? buildRtcCredentials(uid, channelName) : null,
    };
  },
);

exports.getAudioCall = onCall(
  { region: REGION, secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE] },
  async (request) => {
    const uid = requireUid(request);
    const callId = requireString(request.data && request.data.callId, "callId");
    const snapshot = await callRef(callId).get();
    if (!snapshot.exists) throw new HttpsError("not-found", "Call not found.");
    const data = snapshot.data();
    if (uid !== data.callerId && uid !== data.calleeId) {
      throw new HttpsError("permission-denied", "You are not part of this call.");
    }
    const active = data.status === "ringing" || data.status === "connected";
    return {
      success: true,
      call: sanitizedCall(snapshot),
      rtc: active ? buildRtcCredentials(uid, data.channelName) : null,
    };
  },
);

exports.getPendingAudioCall = onCall(
  { region: REGION, secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE] },
  async (request) => {
    const uid = requireUid(request);
    const active = await activeRef(uid).get();
    if (!active.exists) return { success: true, call: null, rtc: null };
    const snapshot = await callRef(active.get("callId")).get();
    if (!snapshot.exists) {
      await active.ref.delete();
      return { success: true, call: null, rtc: null };
    }
    const data = snapshot.data();
    const activeStatus = data.status === "ringing" || data.status === "connected";
    if (!activeStatus) {
      await active.ref.delete();
      return { success: true, call: sanitizedCall(snapshot), rtc: null };
    }
    return {
      success: true,
      call: sanitizedCall(snapshot),
      rtc: buildRtcCredentials(uid, data.channelName),
    };
  },
);

exports.endAudioCall = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const callId = requireString(request.data && request.data.callId, "callId");
  const reason = typeof request.data?.reason === "string" ? request.data.reason.trim().slice(0, 40) : "ended";
  const ref = callRef(callId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) throw new HttpsError("not-found", "Call not found.");
    const data = snapshot.data();
    if (uid !== data.callerId && uid !== data.calleeId) {
      throw new HttpsError("permission-denied", "You are not part of this call.");
    }
    if (["ended", "rejected", "missed", "failed"].includes(data.status)) return;
    await clearActiveUsers(transaction, data, callId);
    transaction.update(ref, {
      status: data.status === "ringing" && uid === data.callerId ? "cancelled" : "ended",
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedBy: uid,
      endReason: reason,
    });
  });
  return { success: true, call: sanitizedCall(await ref.get()) };
});

exports.listAudioCallHistory = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const [asCaller, asCallee] = await Promise.all([
    db.collection("audioCalls").where("callerId", "==", uid).orderBy("createdAt", "desc").limit(HISTORY_LIMIT).get(),
    db.collection("audioCalls").where("calleeId", "==", uid).orderBy("createdAt", "desc").limit(HISTORY_LIMIT).get(),
  ]);
  const unique = new Map();
  for (const doc of [...asCaller.docs, ...asCallee.docs]) unique.set(doc.id, sanitizedCall(doc));
  const calls = [...unique.values()]
    .sort((a, b) => (b.createdAtMs || 0) - (a.createdAtMs || 0))
    .slice(0, HISTORY_LIMIT);
  return { success: true, calls };
});

exports.expireStaleAudioCalls = onSchedule(
  { schedule: "every 1 minutes", region: REGION, timeZone: "UTC" },
  async () => {
    const expired = await db
      .collection("audioCalls")
      .where("status", "==", "ringing")
      .where("expiresAt", "<=", admin.firestore.Timestamp.now())
      .limit(100)
      .get();
    for (const snapshot of expired.docs) {
      await db.runTransaction(async (transaction) => {
        const current = await transaction.get(snapshot.ref);
        if (!current.exists || current.get("status") !== "ringing") return;
        const data = current.data();
        await clearActiveUsers(transaction, data, current.id);
        transaction.update(current.ref, {
          status: "missed",
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          endReason: "ring-timeout",
        });
      });
    }
    logger.info("Stale audio call expiry completed", { expiredCount: expired.size });
  },
);
