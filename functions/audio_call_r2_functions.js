"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const {
  createCallId,
  isTerminalStatus,
  nextStatus,
  normalizeUid,
  participantRole,
  safeDisplayName,
  validCallId,
} = require("./audio_call_r2_logic");
const {
  readPremiumEntitlement,
  requirePremiumEntitlement,
} = require("./premium_entitlement_functions");

const db = admin.firestore();
const REGION = "asia-south1";
const RING_TIMEOUT_SECONDS = 60;
const CALL_MAX_SECONDS = 2 * 60 * 60;
const CLEANUP_LIMIT = 100;

function requireAuthenticatedUid(request) {
  const uid = normalizeUid(request.auth && request.auth.uid);
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function callRef(callId) {
  return db.collection("audioCallsR2").doc(callId);
}

function activePointerRef(uid) {
  return db.collection("activeAudioCallsR2").doc(uid);
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
  const nickname = data && typeof data.nickname === "string" ? data.nickname.trim() : "";
  if (!data || data.isSuspended === true || !nickname) {
    throw new HttpsError(
      "failed-precondition",
      "An active NearMeU profile is required.",
    );
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

function publicCallState(callId, data, viewerUid) {
  const role = participantRole(data, viewerUid);
  if (!role) {
    throw new HttpsError("permission-denied", "Audio call is unavailable.");
  }
  return {
    callId,
    role,
    status: data.status,
    otherUserId: role === "caller" ? data.calleeUid : data.callerUid,
    otherUserName: safeDisplayName(
      role === "caller" ? data.calleeName : data.callerName,
    ),
    createdAtMillis: data.createdAtMillis || null,
    acceptedAtMillis: data.acceptedAtMillis || null,
    endedAtMillis: data.endedAtMillis || null,
    ringExpiresAtMillis: data.ringExpiresAtMillis || null,
    expiresAtMillis: data.expiresAtMillis || null,
    rtcReady: false,
  };
}

function callStillBlocks(data, nowMillis) {
  if (!data || isTerminalStatus(data.status)) return false;
  if (data.status === "ringing") {
    return Number(data.ringExpiresAtMillis || 0) > nowMillis;
  }
  return Number(data.expiresAtMillis || 0) > nowMillis;
}

async function readMatchingPointers(transaction, data) {
  const refs = [activePointerRef(data.callerUid), activePointerRef(data.calleeUid)];
  const snapshots = await Promise.all(refs.map((ref) => transaction.get(ref)));
  return { refs, snapshots };
}

function deleteMatchingPointers(transaction, pointerReads, callId) {
  pointerReads.snapshots.forEach((snapshot, index) => {
    if (snapshot.exists && snapshot.get("callId") === callId) {
      transaction.delete(pointerReads.refs[index]);
    }
  });
}

async function finishCall(callId, status, endedByUid = null) {
  return db.runTransaction(async (transaction) => {
    const ref = callRef(callId);
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return null;
    const data = snapshot.data();
    const pointerReads = await readMatchingPointers(transaction, data);

    if (isTerminalStatus(data.status)) {
      deleteMatchingPointers(transaction, pointerReads, callId);
      return data;
    }

    const nowMillis = Date.now();
    transaction.update(ref, {
      status,
      endedByUid,
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedAtMillis: nowMillis,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    deleteMatchingPointers(transaction, pointerReads, callId);
    return { ...data, status, endedByUid, endedAtMillis: nowMillis };
  });
}

exports.startAudioCallR2 = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
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
    if (blocked) {
      throw new HttpsError("not-found", "This user is unavailable for calls.");
    }

    const callId = createCallId();
    const nowMillis = Date.now();
    const ringExpiresAtMillis = nowMillis + RING_TIMEOUT_SECONDS * 1000;
    const expiresAtMillis = nowMillis + CALL_MAX_SECONDS * 1000;
    const callerPointer = activePointerRef(callerUid);
    const calleePointer = activePointerRef(calleeUid);
    const ref = callRef(callId);

    await db.runTransaction(async (transaction) => {
      const [callerActive, calleeActive] = await Promise.all([
        transaction.get(callerPointer),
        transaction.get(calleePointer),
      ]);
      const entries = [
        { ref: callerPointer, snapshot: callerActive },
        { ref: calleePointer, snapshot: calleeActive },
      ];
      const oldCalls = new Map();

      for (const entry of entries) {
        if (!entry.snapshot.exists) continue;
        const oldCallId = entry.snapshot.get("callId");
        if (!validCallId(oldCallId) || oldCalls.has(oldCallId)) continue;
        oldCalls.set(oldCallId, await transaction.get(callRef(oldCallId)));
      }

      for (const entry of entries) {
        if (!entry.snapshot.exists) continue;
        const oldCallId = entry.snapshot.get("callId");
        const oldCallSnapshot = validCallId(oldCallId) ? oldCalls.get(oldCallId) : null;
        const oldData = oldCallSnapshot && oldCallSnapshot.exists
          ? oldCallSnapshot.data()
          : null;
        const stale = !validCallId(oldCallId) || !oldData || !callStillBlocks(oldData, nowMillis);

        if (!stale) {
          throw new HttpsError(
            "resource-exhausted",
            "One of you is already in another call.",
          );
        }

        transaction.delete(entry.ref);
        if (
          oldCallSnapshot &&
          oldCallSnapshot.exists &&
          oldData &&
          !isTerminalStatus(oldData.status)
        ) {
          transaction.update(oldCallSnapshot.ref, {
            status: oldData.status === "ringing" ? "missed" : "expired",
            endedAt: admin.firestore.FieldValue.serverTimestamp(),
            endedAtMillis: nowMillis,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      const callData = {
        schemaVersion: 2,
        type: "audio",
        callerUid,
        calleeUid,
        callerName: safeDisplayName(callerProfile.get("nickname")),
        calleeName: safeDisplayName(calleeProfile.get("nickname")),
        participants: [callerUid, calleeUid].sort(),
        status: "ringing",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAtMillis: nowMillis,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ringExpiresAtMillis,
        expiresAtMillis,
      };
      transaction.create(ref, callData);
      const pointerData = {
        callId,
        expiresAtMillis,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      transaction.set(callerPointer, pointerData);
      transaction.set(calleePointer, pointerData);
    });

    const created = await ref.get();
    return publicCallState(callId, created.data(), callerUid);
  },
);

exports.getAudioCallR2 = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const callId = requireCallId(request);
    const snapshot = await callRef(callId).get();
    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Audio call is unavailable.");
    }
    const data = snapshot.data();
    const role = participantRole(data, uid);
    if (!role) {
      throw new HttpsError("permission-denied", "Audio call is unavailable.");
    }

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

    const nowMillis = Date.now();
    if (data.status === "ringing" && nowMillis >= Number(data.ringExpiresAtMillis || 0)) {
      const finished = await finishCall(callId, "missed", null);
      return publicCallState(callId, finished, uid);
    }
    if (!isTerminalStatus(data.status) && nowMillis >= Number(data.expiresAtMillis || 0)) {
      const finished = await finishCall(callId, "expired", null);
      return publicCallState(callId, finished, uid);
    }
    return publicCallState(callId, data, uid);
  },
);

exports.respondAudioCallR2 = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const callId = requireCallId(request);
    const action = request.data && request.data.action;
    if (action !== "accept" && action !== "decline") {
      throw new HttpsError("invalid-argument", "Choose accept or decline.");
    }

    const ref = callRef(callId);
    const result = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw new HttpsError("not-found", "Audio call is unavailable.");
      }
      const data = snapshot.data();
      const role = participantRole(data, uid);
      if (role !== "callee") {
        throw new HttpsError("permission-denied", "Only the receiver can answer this call.");
      }

      const nowMillis = Date.now();
      if (data.status === "ringing" && nowMillis >= Number(data.ringExpiresAtMillis || 0)) {
        throw new HttpsError("failed-precondition", "This call is no longer ringing.");
      }

      let status;
      try {
        status = nextStatus({ status: data.status, actorRole: role, action });
      } catch (_) {
        throw new HttpsError("failed-precondition", "This call can no longer be changed.");
      }

      const pointerReads = await readMatchingPointers(transaction, data);
      const updates = {
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (status === "accepted") {
        updates.acceptedAt = admin.firestore.FieldValue.serverTimestamp();
        updates.acceptedAtMillis = nowMillis;
      } else {
        updates.endedAt = admin.firestore.FieldValue.serverTimestamp();
        updates.endedAtMillis = nowMillis;
        updates.endedByUid = uid;
        deleteMatchingPointers(transaction, pointerReads, callId);
      }
      transaction.update(ref, updates);
      return { ...data, ...updates, status, acceptedAtMillis: updates.acceptedAtMillis || null, endedAtMillis: updates.endedAtMillis || null };
    });
    return publicCallState(callId, result, uid);
  },
);

exports.endAudioCallR2 = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const callId = requireCallId(request);
    const snapshot = await callRef(callId).get();
    if (!snapshot.exists) return { callId, status: "ended", alreadyGone: true };
    const data = snapshot.data();
    const role = participantRole(data, uid);
    if (!role) {
      throw new HttpsError("permission-denied", "Audio call is unavailable.");
    }
    const finished = await finishCall(callId, "ended", uid);
    return publicCallState(callId, finished || { ...data, status: "ended" }, uid);
  },
);

exports.expireStaleAudioCallsR2 = onSchedule(
  {
    schedule: "every 5 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async () => {
    const nowMillis = Date.now();
    const snapshot = await db
      .collection("audioCallsR2")
      .where("status", "in", ["ringing", "accepted"])
      .limit(CLEANUP_LIMIT)
      .get();

    let expired = 0;
    for (const document of snapshot.docs) {
      const data = document.data();
      const stale = data.status === "ringing"
        ? nowMillis >= Number(data.ringExpiresAtMillis || 0)
        : nowMillis >= Number(data.expiresAtMillis || 0);
      if (!stale) continue;
      await finishCall(document.id, data.status === "ringing" ? "missed" : "expired", null);
      expired += 1;
    }
    return { scanned: snapshot.size, expired };
  },
);
