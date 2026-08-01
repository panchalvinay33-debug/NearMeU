"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");

const {
  normalizeClearChatRequest,
  isExactPrivateChatParticipants,
  shouldHideMessageThroughClear,
} = require("./chat_clear_logic");

const db = admin.firestore();
const REGION = "asia-south1";
const CLEAR_POLICY_VERSION = 1;
const MESSAGE_PAGE_LIMIT = 400;

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
}

async function hideMessagesThroughClear({ chatRef, actorId, clearedAt }) {
  let cursor = null;
  let hiddenCount = 0;

  while (true) {
    let query = chatRef
      .collection("messages")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(MESSAGE_PAGE_LIMIT);
    if (cursor) query = query.startAfter(cursor);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    const batch = db.batch();
    let writeCount = 0;
    const clearedAtMs = clearedAt.toMillis();

    for (const message of snapshot.docs) {
      const data = message.data() || {};
      const deletedFor = Array.isArray(data.deletedFor) ? data.deletedFor : [];
      if (deletedFor.includes(actorId)) continue;
      if (!shouldHideMessageThroughClear(timestampMillis(data.timestamp), clearedAtMs)) {
        continue;
      }
      batch.update(message.ref, {
        deletedFor: admin.firestore.FieldValue.arrayUnion(actorId),
      });
      writeCount += 1;
    }

    if (writeCount > 0) {
      await batch.commit();
      hiddenCount += writeCount;
    }

    cursor = snapshot.docs[snapshot.docs.length - 1];
  }

  return hiddenCount;
}

exports.clearPrivateChat = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (request) => {
    const actorId = requireAuthenticatedUid(request);
    let clearRequest;
    try {
      clearRequest = normalizeClearChatRequest(request.data, actorId);
    } catch (error) {
      throw new HttpsError("invalid-argument", error.message);
    }

    const chatRef = db.collection("chats").doc(clearRequest.chatId);
    const clearedAt = admin.firestore.Timestamp.now();

    await db.runTransaction(async (transaction) => {
      const chatSnapshot = await transaction.get(chatRef);
      if (!chatSnapshot.exists) {
        throw new HttpsError("not-found", "This chat is no longer available.");
      }

      const chat = chatSnapshot.data() || {};
      if (
        !isExactPrivateChatParticipants(
          chat.participants,
          actorId,
          clearRequest.otherUserId,
        )
      ) {
        throw new HttpsError("permission-denied", "Invalid private chat.");
      }

      transaction.update(
        chatRef,
        new admin.firestore.FieldPath("clearStates", actorId, "clearedAt"),
        clearedAt,
        new admin.firestore.FieldPath("clearStates", actorId, "policyVersion"),
        CLEAR_POLICY_VERSION,
        new admin.firestore.FieldPath("unreadCounts", actorId),
        0,
        new admin.firestore.FieldPath("readStates", actorId, "unreadCount"),
        0,
        new admin.firestore.FieldPath("readStates", actorId, "lastReadAt"),
        clearedAt,
      );
    });

    const hiddenMessageCount = await hideMessagesThroughClear({
      chatRef,
      actorId,
      clearedAt,
    });

    logger.info("Private chat cleared for participant", {
      chatId: clearRequest.chatId,
      actorId,
      hiddenMessageCount,
      policyVersion: CLEAR_POLICY_VERSION,
    });

    return {
      success: true,
      clearedAtMillis: clearedAt.toMillis(),
      hiddenMessageCount,
      policyVersion: CLEAR_POLICY_VERSION,
    };
  },
);
