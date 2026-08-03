"use strict";

const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const REGION = "asia-south1";
const CLEANUP_LIMIT = 100;
const db = admin.firestore();

function activePointerRef(uid) {
  return db.collection("activeAudioCalls").doc(uid);
}

async function expireRingingCall(document, nowMillis) {
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(document.ref);
    if (!snapshot.exists) return;
    const data = snapshot.data();
    if (data.status !== "ringing") return;
    if (Number(data.ringExpiresAtMillis || 0) > nowMillis) return;

    transaction.update(document.ref, {
      status: "missed",
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedAtMillis: nowMillis,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const callerPointer = activePointerRef(data.callerUid);
    const calleePointer = activePointerRef(data.calleeUid);
    const [callerSnapshot, calleeSnapshot] = await Promise.all([
      transaction.get(callerPointer),
      transaction.get(calleePointer),
    ]);

    if (callerSnapshot.exists && callerSnapshot.get("callId") === document.id) {
      transaction.delete(callerPointer);
    }
    if (calleeSnapshot.exists && calleeSnapshot.get("callId") === document.id) {
      transaction.delete(calleePointer);
    }
  });
}

exports.expireStaleRingingAudioCalls = onSchedule(
  {
    schedule: "every 1 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    const nowMillis = Date.now();
    const snapshot = await db
      .collection("audioCalls")
      .where("ringExpiresAtMillis", "<=", nowMillis)
      .limit(CLEANUP_LIMIT)
      .get();

    for (const document of snapshot.docs) {
      await expireRingingCall(document, nowMillis);
    }
  },
);
