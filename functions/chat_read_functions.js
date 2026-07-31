"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const db = admin.firestore();
const REGION = "asia-south1";
const BATCH_LIMIT = 400;

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

function chatIdFor(firstUid, secondUid) {
  return [firstUid, secondUid].sort().join("_");
}

exports.markPrivateChatRead = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const otherUserId = normalizedUserId(
      request.data && request.data.otherUserId,
    );
    if (uid === otherUserId) {
      throw new HttpsError("invalid-argument", "A private chat peer is required.");
    }

    const chatId = chatIdFor(uid, otherUserId);
    const chatRef = db.collection("chats").doc(chatId);
    const userRef = db.collection("users").doc(uid);
    const now = admin.firestore.Timestamp.now();

    await db.runTransaction(async (transaction) => {
      const [chat, user] = await Promise.all([
        transaction.get(chatRef),
        transaction.get(userRef),
      ]);
      if (!user.exists || user.get("isSuspended") === true) {
        throw new HttpsError(
          "failed-precondition",
          "An active NearMeU profile is required.",
        );
      }
      if (!chat.exists) return;
      const participants = chat.get("participants");
      if (
        !Array.isArray(participants) ||
        participants.length !== 2 ||
        !participants.includes(uid) ||
        !participants.includes(otherUserId)
      ) {
        throw new HttpsError("permission-denied", "This chat is not available.");
      }

      transaction.update(
        chatRef,
        new admin.firestore.FieldPath("unreadCounts", uid),
        0,
        new admin.firestore.FieldPath("readStates", uid, "unreadCount"),
        0,
        new admin.firestore.FieldPath("readStates", uid, "lastReadAt"),
        now,
      );
    });

    let updatedMessages = 0;
    while (true) {
      const unread = await chatRef
        .collection("messages")
        .where("receiverId", "==", uid)
        .where("isSeen", "==", false)
        .limit(BATCH_LIMIT)
        .get();
      if (unread.empty) break;

      const batch = db.batch();
      for (const message of unread.docs) {
        batch.update(message.ref, {
          isDelivered: true,
          deliveredAt: message.get("deliveredAt") || now,
          isSeen: true,
          seenAt: now,
        });
      }
      await batch.commit();
      updatedMessages += unread.size;
      if (unread.size < BATCH_LIMIT) break;
    }

    return { success: true, chatId, updatedMessages };
  },
);
