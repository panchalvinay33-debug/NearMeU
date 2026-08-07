"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

const db = admin.firestore();
const REGION = "asia-south1";
const TERMINAL_STATUSES = new Set([
  "ended",
  "rejected",
  "missed",
  "failed",
  "cancelled",
]);

function activeRef(uid) {
  return db.collection("activeAudioCallUsers").doc(uid);
}

function callRef(callId) {
  return db.collection("audioCalls").doc(callId);
}

async function terminateActiveAudioCallForUser(uid, reason) {
  if (!uid) return false;
  const active = await activeRef(uid).get();
  if (!active.exists) return false;
  const callId = active.get("callId");
  if (typeof callId !== "string" || !callId) {
    await active.ref.delete();
    return false;
  }

  let terminated = false;
  await db.runTransaction(async (transaction) => {
    const call = await transaction.get(callRef(callId));
    if (!call.exists) {
      transaction.delete(activeRef(uid));
      return;
    }
    const data = call.data() || {};
    const callerId = typeof data.callerId === "string" ? data.callerId : "";
    const calleeId = typeof data.calleeId === "string" ? data.calleeId : "";
    const activeEntries = await Promise.all(
      [callerId, calleeId]
        .filter(Boolean)
        .map(async (participantId) => ({
          ref: activeRef(participantId),
          snapshot: await transaction.get(activeRef(participantId)),
        })),
    );

    for (const entry of activeEntries) {
      if (entry.snapshot.exists && entry.snapshot.get("callId") === callId) {
        transaction.delete(entry.ref);
      }
    }

    if (TERMINAL_STATUSES.has(data.status)) return;
    transaction.update(call.ref, {
      status: "ended",
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedBy: uid,
      endReason: reason,
    });
    terminated = true;
  });

  if (terminated) logger.info("Active audio call terminated by safety event", { uid, callId, reason });
  return terminated;
}

exports.endAudioCallOnBlock = onDocumentCreated(
  {
    document: "users/{blockerId}/blocks/{blockedUserId}",
    region: REGION,
  },
  async (event) => {
    await Promise.all([
      terminateActiveAudioCallForUser(event.params.blockerId, "blocked"),
      terminateActiveAudioCallForUser(event.params.blockedUserId, "blocked"),
    ]);
  },
);

exports.endAudioCallOnSuspension = onDocumentUpdated(
  {
    document: "users/{uid}",
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data() || {};
    const after = event.data?.after.data() || {};
    if (before.isSuspended === true || after.isSuspended !== true) return;
    await terminateActiveAudioCallForUser(event.params.uid, "account-suspended");
  },
);

exports.endAudioCallOnUserDelete = onDocumentDeleted(
  {
    document: "users/{uid}",
    region: REGION,
  },
  async (event) => {
    await terminateActiveAudioCallForUser(event.params.uid, "account-deleted");
  },
);
