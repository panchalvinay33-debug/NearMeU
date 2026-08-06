"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const db = admin.firestore();
const REGION = "asia-south1";
// Client delivery lifecycle deliberately scans at most 200 recent undelivered
// messages. Keep the trusted callable aligned so an older backlog cannot reject
// the entire receipt batch and hide the delivered state for new messages.
const MAX_MESSAGE_IDS = 200;

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function normalizedUserId(value) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "otherUserId is required.");
  }
  const uid = value.trim();
  if (!uid || uid.length > 128) {
    throw new HttpsError("invalid-argument", "otherUserId is invalid.");
  }
  return uid;
}

function normalizedMessageIds(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError("invalid-argument", "messageIds are required.");
  }
  const ids = [...new Set(value)]
    .filter((id) => typeof id === "string")
    .map((id) => id.trim())
    .filter((id) => id.length > 0 && id.length <= 256);
  if (ids.length === 0 || ids.length > MAX_MESSAGE_IDS) {
    throw new HttpsError("invalid-argument", "messageIds are invalid.");
  }
  return ids;
}

function chatIdFor(firstUid, secondUid) {
  return [firstUid, secondUid].sort().join("_");
}

exports.acknowledgePrivateMessagesDelivered = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const otherUserId = normalizedUserId(
      request.data && request.data.otherUserId,
    );
    const messageIds = normalizedMessageIds(
      request.data && request.data.messageIds,
    );
    if (uid === otherUserId) {
      throw new HttpsError("invalid-argument", "A private chat peer is required.");
    }

    const chatId = chatIdFor(uid, otherUserId);
    const chatRef = db.collection("chats").doc(chatId);
    const [chat, user] = await Promise.all([
      chatRef.get(),
      db.collection("users").doc(uid).get(),
    ]);

    if (!user.exists || user.get("isSuspended") === true) {
      throw new HttpsError(
        "failed-precondition",
        "An active NearMeU profile is required.",
      );
    }
    if (!chat.exists) return { success: true, chatId, updatedMessages: 0 };

    const participants = chat.get("participants");
    if (
      !Array.isArray(participants) ||
      participants.length !== 2 ||
      !participants.includes(uid) ||
      !participants.includes(otherUserId)
    ) {
      throw new HttpsError("permission-denied", "This chat is not available.");
    }

    const now = admin.firestore.Timestamp.now();
    let updatedMessages = 0;
    const refs = messageIds.map((id) => chatRef.collection("messages").doc(id));
    const snapshots = await db.getAll(...refs);
    const batch = db.batch();

    for (const snapshot of snapshots) {
      if (!snapshot.exists) continue;
      if (snapshot.get("receiverId") !== uid) continue;
      if (snapshot.get("senderId") !== otherUserId) continue;
      if (snapshot.get("isDelivered") === true) continue;
      batch.update(snapshot.ref, {
        isDelivered: true,
        deliveredAt: now,
      });
      updatedMessages += 1;
    }

    if (updatedMessages > 0) await batch.commit();
    return { success: true, chatId, updatedMessages };
  },
);
