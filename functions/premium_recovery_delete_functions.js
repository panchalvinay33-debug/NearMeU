"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const {
  deleteRecoveryMessageForUser,
} = require("./premium_recovery_functions");

const db = admin.firestore();
const REGION = "asia-south1";

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function validId(value) {
  return typeof value === "string" && value.length > 0 && value.length <= 200;
}

function deterministicChatId(uid1, uid2) {
  return [uid1, uid2].sort().join("_");
}

exports.deleteMyPremiumRecoveryMessage = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const data = request.data || {};
    const otherUserId = data.otherUserId;
    const messageId = data.messageId;
    if (!validId(otherUserId) || otherUserId === uid || !validId(messageId)) {
      throw new HttpsError("invalid-argument", "Valid message details are required.");
    }

    const chatId = deterministicChatId(uid, otherUserId);
    const chatSnapshot = await db.collection("chats").doc(chatId).get();
    if (!chatSnapshot.exists) {
      throw new HttpsError("not-found", "This chat is no longer available.");
    }
    const participants = Array.isArray(chatSnapshot.get("participants"))
      ? [...chatSnapshot.get("participants")].sort()
      : [];
    const expected = [uid, otherUserId].sort();
    if (
      participants.length !== 2 ||
      participants[0] !== expected[0] ||
      participants[1] !== expected[1]
    ) {
      throw new HttpsError("permission-denied", "Invalid private chat.");
    }

    const deleted = await deleteRecoveryMessageForUser({
      uid,
      chatId,
      messageId,
    });
    return { success: true, deleted };
  },
);
