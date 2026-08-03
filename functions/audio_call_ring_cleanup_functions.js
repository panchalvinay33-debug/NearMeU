"use strict";

const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const REGION = "asia-south1";
const CLEANUP_LIMIT = 100;
const TERMINAL_STATUSES = new Set(["declined", "ended", "missed", "expired"]);
const db = admin.firestore();

function activePointerRef(uid) {
  return db.collection("activeAudioCalls").doc(uid);
}

function validCallId(value) {
  return typeof value === "string" && /^[A-Za-z0-9_-]{20,64}$/.test(value);
}

async function expireRingingCall(document, nowMillis) {
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(document.ref);
    if (!snapshot.exists) return;
    const data = snapshot.data();
    if (data.status !== "ringing") return;
    if (Number(data.ringExpiresAtMillis || 0) > nowMillis) return;

    const callerPointer = activePointerRef(data.callerUid);
    const calleePointer = activePointerRef(data.calleeUid);
    const [callerSnapshot, calleeSnapshot] = await Promise.all([
      transaction.get(callerPointer),
      transaction.get(calleePointer),
    ]);

    transaction.update(document.ref, {
      status: "missed",
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedAtMillis: nowMillis,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (callerSnapshot.exists && callerSnapshot.get("callId") === document.id) {
      transaction.delete(callerPointer);
    }
    if (calleeSnapshot.exists && calleeSnapshot.get("callId") === document.id) {
      transaction.delete(calleePointer);
    }
  });
}

async function scrubActivePointer(pointerDocument, nowMillis) {
  await db.runTransaction(async (transaction) => {
    const pointerSnapshot = await transaction.get(pointerDocument.ref);
    if (!pointerSnapshot.exists) return;

    const pointer = pointerSnapshot.data();
    const callId = pointer.callId;
    if (!validCallId(callId)) {
      transaction.delete(pointerDocument.ref);
      return;
    }

    const callDocument = db.collection("audioCalls").doc(callId);
    const callSnapshot = await transaction.get(callDocument);

    if (!callSnapshot.exists) {
      transaction.delete(pointerDocument.ref);
      return;
    }

    const call = callSnapshot.data();
    const status = call.status;
    const pointerExpiresAtMillis = Number(pointer.expiresAtMillis || 0);
    const callExpiresAtMillis = Number(call.expiresAtMillis || 0);
    const ringExpiresAtMillis = Number(call.ringExpiresAtMillis || 0);

    const isTerminal = TERMINAL_STATUSES.has(status);
    const ringExpired = status === "ringing" && ringExpiresAtMillis > 0 && ringExpiresAtMillis <= nowMillis;
    const callExpired = !isTerminal && callExpiresAtMillis > 0 && callExpiresAtMillis <= nowMillis;
    const pointerExpired = Number.isFinite(pointerExpiresAtMillis) && pointerExpiresAtMillis > 0 && pointerExpiresAtMillis <= nowMillis;

    if (!isTerminal && !ringExpired && !callExpired && !pointerExpired) return;

    transaction.delete(pointerDocument.ref);

    if (ringExpired) {
      transaction.update(callDocument, {
        status: "missed",
        endedAt: admin.firestore.FieldValue.serverTimestamp(),
        endedAtMillis: nowMillis,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else if (callExpired && !isTerminal) {
      transaction.update(callDocument, {
        status: "expired",
        endedAt: admin.firestore.FieldValue.serverTimestamp(),
        endedAtMillis: nowMillis,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
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

    const [ringingSnapshot, pointerSnapshot] = await Promise.all([
      db
        .collection("audioCalls")
        .where("ringExpiresAtMillis", "<=", nowMillis)
        .limit(CLEANUP_LIMIT)
        .get(),
      db.collection("activeAudioCalls").limit(CLEANUP_LIMIT).get(),
    ]);

    for (const document of ringingSnapshot.docs) {
      await expireRingingCall(document, nowMillis);
    }

    for (const document of pointerSnapshot.docs) {
      await scrubActivePointer(document, nowMillis);
    }
  },
);
