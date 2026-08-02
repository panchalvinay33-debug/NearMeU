"use strict";

const { HttpsError, onCall } = require("firebase-functions/v2/https");

const {
  deleteRecoveryMessageForUser,
} = require("./premium_recovery_functions");

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

    // The caller can only address a record inside their own recovery root.
    // Do not depend on the seven-day delivery chat still existing: Delete for
    // Me must remain authoritative even after the source message has expired.
    const chatId = deterministicChatId(uid, otherUserId);
    const deleted = await deleteRecoveryMessageForUser({
      uid,
      chatId,
      messageId,
    });
    return { success: true, deleted };
  },
);
