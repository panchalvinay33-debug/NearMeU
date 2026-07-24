"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const {
  normalizeUnsendRequest,
  unsendDecision,
} = require("./message_unsend_logic");
const {
  privateMediaPathAllowed,
} = require("./message_retention_logic");
const {
  refreshChatMetadata,
} = require("./message_retention_functions");

const db = admin.firestore();
const REGION = "asia-south1";
const PENDING_DELETE_LIMIT = 300;
const UNSEND_POLICY_VERSION = 1;

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function activeProfile(snapshot, uid) {
  if (!snapshot.exists) {
    throw new HttpsError(
      "failed-precondition",
      "An active NearMeU profile is required.",
    );
  }
  if (snapshot.get("isSuspended") === true) {
    throw new HttpsError("permission-denied", "This account is suspended.");
  }
  const age = snapshot.get("age");
  if (!Number.isInteger(age) || age < 18 || snapshot.id !== uid) {
    throw new HttpsError(
      "failed-precondition",
      "An adult NearMeU profile is required.",
    );
  }
}

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
}

function parentChatReference(messageSnapshot) {
  const chatRef = messageSnapshot.ref.parent.parent;
  if (!chatRef || chatRef.parent.id !== "chats") return null;
  return chatRef;
}

async function deletePendingMedia({
  messageRef,
  storagePath,
  senderId,
  chatId,
  messageId,
  reason,
}) {
  const validPath = privateMediaPathAllowed({
    path: storagePath,
    senderId,
    chatId,
    messageId,
  });

  if (!validPath) {
    await messageRef.set(
      {
        mediaStoragePath: null,
        cloudMediaDeletePending: false,
        cloudMediaDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
        cloudMediaDeleteReason: "invalid_private_path",
      },
      { merge: true },
    );
    return { deleted: false, pending: false };
  }

  try {
    await admin.storage().bucket().file(storagePath).delete({
      ignoreNotFound: true,
    });
    await messageRef.set(
      {
        mediaStoragePath: null,
        cloudMediaDeletePending: false,
        cloudMediaDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
        cloudMediaDeleteReason: reason,
      },
      { merge: true },
    );
    return { deleted: true, pending: false };
  } catch (error) {
    logger.error("Private media deletion deferred", {
      chatId,
      messageId,
      reason,
      error,
    });
    return { deleted: false, pending: true };
  }
}

async function refreshMetadataSafely(chatRef, messageId, source) {
  try {
    await refreshChatMetadata(chatRef);
  } catch (error) {
    logger.error("Chat preview refresh after unsend failed", {
      chatId: chatRef.id,
      messageId,
      source,
      error,
    });
  }
}

exports.unsendPrivateMessage = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (request) => {
    const actorId = requireAuthenticatedUid(request);
    let unsendRequest;
    try {
      unsendRequest = normalizeUnsendRequest(request.data, actorId);
    } catch (error) {
      throw new HttpsError("invalid-argument", error.message);
    }

    const userRef = db.collection("users").doc(actorId);
    const chatRef = db.collection("chats").doc(unsendRequest.chatId);
    const messageRef = chatRef
      .collection("messages")
      .doc(unsendRequest.messageId);

    const result = await db.runTransaction(async (transaction) => {
      const [userSnapshot, chatSnapshot, messageSnapshot] = await Promise.all([
        transaction.get(userRef),
        transaction.get(chatRef),
        transaction.get(messageRef),
      ]);
      activeProfile(userSnapshot, actorId);

      if (!chatSnapshot.exists || !messageSnapshot.exists) {
        throw new HttpsError("not-found", "This message is no longer available.");
      }

      const chat = chatSnapshot.data() || {};
      const message = messageSnapshot.data() || {};
      const participants = Array.isArray(chat.participants)
        ? [...chat.participants].sort()
        : [];
      const expectedParticipants = [actorId, unsendRequest.otherUserId].sort();
      if (
        participants.length !== 2 ||
        participants[0] !== expectedParticipants[0] ||
        participants[1] !== expectedParticipants[1]
      ) {
        throw new HttpsError("failed-precondition", "Invalid private chat.");
      }

      const now = admin.firestore.Timestamp.now();
      const decision = unsendDecision({
        actorId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        otherUserId: unsendRequest.otherUserId,
        isUnsent: message.isUnsent === true,
        timestampMs: timestampMillis(message.timestamp),
        nowMs: now.toMillis(),
      });
      if (!decision.allowed) {
        const code = decision.reason === "window-expired"
          ? "failed-precondition"
          : "permission-denied";
        const userMessage = decision.reason === "window-expired"
          ? "Messages can only be unsent within 60 minutes."
          : "You cannot unsend this message.";
        throw new HttpsError(code, userMessage, { reason: decision.reason });
      }

      const storagePath = typeof message.mediaStoragePath === "string"
        ? message.mediaStoragePath
        : null;
      if (decision.alreadyUnsent) {
        return {
          storagePath,
          senderId: message.senderId,
          alreadyUnsent: true,
        };
      }

      transaction.update(messageRef, {
        text: "",
        isUnsent: true,
        unsentAt: now,
        replyToMessageId: null,
        replyToText: null,
        replyToSenderId: null,
        type: "text",
        mediaUrl: null,
        mediaContentType: null,
        mediaSizeBytes: null,
        mediaDurationMs: null,
        cloudMediaDeletePending: Boolean(storagePath),
        cloudMediaDeleteReason: storagePath ? "unsent" : null,
        unsendSource: "trusted_backend",
        unsendPolicyVersion: UNSEND_POLICY_VERSION,
      });

      return {
        storagePath,
        senderId: message.senderId,
        alreadyUnsent: false,
      };
    });

    await refreshMetadataSafely(
      chatRef,
      unsendRequest.messageId,
      "trusted_backend",
    );

    let mediaCleanup = { deleted: false, pending: false };
    if (result.storagePath) {
      mediaCleanup = await deletePendingMedia({
        messageRef,
        storagePath: result.storagePath,
        senderId: result.senderId,
        chatId: unsendRequest.chatId,
        messageId: unsendRequest.messageId,
        reason: "unsent",
      });
    }

    return {
      success: true,
      alreadyUnsent: result.alreadyUnsent,
      cloudMediaDeleted: mediaCleanup.deleted,
      cleanupPending: mediaCleanup.pending,
    };
  },
);

// Older app versions used a tightly constrained direct Firestore unsend. This
// trigger keeps those clients safe during rollout: valid requests receive the
// same media cleanup, while attempts outside the server-side 60-minute window
// are restored from the before snapshot.
exports.guardLegacyPrivateMessageUnsend = onDocumentUpdated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const beforeSnapshot = event.data && event.data.before;
    const afterSnapshot = event.data && event.data.after;
    if (!beforeSnapshot || !afterSnapshot) return;

    const before = beforeSnapshot.data() || {};
    const after = afterSnapshot.data() || {};
    if (before.isUnsent === true || after.isUnsent !== true) return;
    if (after.unsendSource === "trusted_backend") return;

    const chatRef = parentChatReference(afterSnapshot);
    if (!chatRef) return;

    const eventTimeMs = Date.parse(event.time || "");
    const decision = unsendDecision({
      actorId: before.senderId,
      senderId: before.senderId,
      receiverId: before.receiverId,
      otherUserId: before.receiverId,
      isUnsent: false,
      timestampMs: timestampMillis(before.timestamp),
      nowMs: Number.isFinite(eventTimeMs) ? eventTimeMs : Date.now(),
    });

    if (!decision.allowed) {
      await afterSnapshot.ref.set(
        {
          text: before.text || "",
          isUnsent: before.isUnsent === true,
          unsentAt: before.unsentAt || null,
          replyToMessageId: before.replyToMessageId || null,
          replyToText: before.replyToText || null,
          replyToSenderId: before.replyToSenderId || null,
          type: before.type || "text",
          mediaUrl: before.mediaUrl || null,
          mediaStoragePath: before.mediaStoragePath || null,
          mediaContentType: before.mediaContentType || null,
          mediaSizeBytes: before.mediaSizeBytes || null,
          mediaDurationMs: before.mediaDurationMs || null,
          cloudMediaDeletePending: before.cloudMediaDeletePending === true,
          cloudMediaDeleteReason: before.cloudMediaDeleteReason || null,
          unsendSource: before.unsendSource || admin.firestore.FieldValue.delete(),
          unsendPolicyVersion:
            before.unsendPolicyVersion || admin.firestore.FieldValue.delete(),
        },
        { merge: true },
      );
      await refreshMetadataSafely(
        chatRef,
        afterSnapshot.id,
        "legacy_client_restore",
      );
      logger.warn("Legacy direct unsend restored after server validation", {
        chatId: chatRef.id,
        messageId: afterSnapshot.id,
        reason: decision.reason,
      });
      return;
    }

    const storagePath = typeof before.mediaStoragePath === "string"
      ? before.mediaStoragePath
      : null;
    await afterSnapshot.ref.set(
      {
        cloudMediaDeletePending: Boolean(storagePath),
        cloudMediaDeleteReason: storagePath ? "legacy_unsent" : null,
        unsendSource: "legacy_client_guard",
        unsendPolicyVersion: UNSEND_POLICY_VERSION,
      },
      { merge: true },
    );
    await refreshMetadataSafely(
      chatRef,
      afterSnapshot.id,
      "legacy_client_guard",
    );

    if (storagePath) {
      await deletePendingMedia({
        messageRef: afterSnapshot.ref,
        storagePath,
        senderId: before.senderId,
        chatId: chatRef.id,
        messageId: afterSnapshot.id,
        reason: "legacy_unsent",
      });
    }
  },
);

exports.retryPendingPrivateMediaDeletes = onSchedule(
  {
    schedule: "every 60 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const pending = await db
      .collectionGroup("messages")
      .where("cloudMediaDeletePending", "==", true)
      .limit(PENDING_DELETE_LIMIT)
      .get();
    if (pending.empty) return;

    let deleted = 0;
    let stillPending = 0;
    for (const messageSnapshot of pending.docs) {
      const chatRef = parentChatReference(messageSnapshot);
      const data = messageSnapshot.data() || {};
      if (!chatRef) {
        await messageSnapshot.ref.set(
          {
            mediaStoragePath: null,
            cloudMediaDeletePending: false,
            cloudMediaDeleteReason: "invalid_chat_path",
          },
          { merge: true },
        );
        continue;
      }

      const outcome = await deletePendingMedia({
        messageRef: messageSnapshot.ref,
        storagePath: data.mediaStoragePath,
        senderId: data.senderId,
        chatId: chatRef.id,
        messageId: messageSnapshot.id,
        reason: data.cloudMediaDeleteReason || "scheduled_retry",
      });
      if (outcome.deleted) deleted += 1;
      if (outcome.pending) stillPending += 1;
    }

    logger.info("Pending private media deletions processed", {
      processed: pending.size,
      deleted,
      stillPending,
    });
  },
);
