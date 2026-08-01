"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const {
  messageRateDecision,
  normalizedReply,
} = require("./anti_abuse_logic");
const {
  normalizePrivateMediaRequest,
  validateStoredMedia,
} = require("./private_media_logic");
const {
  readPremiumEntitlement,
  requirePremiumEntitlement,
} = require("./premium_entitlement_functions");

const db = admin.firestore();
const REGION = "asia-south1";

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
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

async function deleteRejectedUpload(storagePath) {
  try {
    await admin.storage().bucket().file(storagePath).delete({
      ignoreNotFound: true,
    });
  } catch (error) {
    logger.error("Rejected private media cleanup failed", {
      storagePath,
      error,
    });
  }
}

exports.sendPrivateMediaMessage = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (request) => {
    const senderId = requireAuthenticatedUid(request);
    let media;
    let reply;

    try {
      media = normalizePrivateMediaRequest(request.data, senderId);
      reply = normalizedReply(
        request.data && request.data.replyTo,
        [senderId, media.receiverId],
      );
    } catch (error) {
      throw new HttpsError("invalid-argument", error.message);
    }

    const entitlement = await readPremiumEntitlement(senderId);
    requirePremiumEntitlement(entitlement, `send-${media.type}`);

    const file = admin.storage().bucket().file(media.storagePath);
    let storedMedia;
    try {
      const [exists] = await file.exists();
      if (!exists) {
        throw new TypeError("Uploaded media could not be found.");
      }
      const [objectMetadata] = await file.getMetadata();
      storedMedia = validateStoredMedia({
        type: media.type,
        sizeBytes: objectMetadata.size,
        contentType: objectMetadata.contentType,
        metadata: objectMetadata.metadata,
        senderId,
        receiverId: media.receiverId,
        chatId: media.chatId,
        messageId: media.messageId,
      });
    } catch (error) {
      await deleteRejectedUpload(media.storagePath);
      throw new HttpsError("invalid-argument", error.message);
    }

    const participants = [senderId, media.receiverId].sort();
    const chatRef = db.collection("chats").doc(media.chatId);
    const messageRef = chatRef.collection("messages").doc(media.messageId);
    const senderRef = db.collection("users").doc(senderId);
    const receiverRef = db.collection("users").doc(media.receiverId);
    const blockedBySenderRef = senderRef
      .collection("blocks")
      .doc(media.receiverId);
    const blockedByReceiverRef = receiverRef.collection("blocks").doc(senderId);
    const abuseRef = db.collection("antiAbuseUsers").doc(senderId);

    try {
      const result = await db.runTransaction(async (transaction) => {
        const [
          senderSnapshot,
          receiverSnapshot,
          blockedBySender,
          blockedByReceiver,
          chatSnapshot,
          abuseSnapshot,
          existingMessage,
        ] = await Promise.all([
          transaction.get(senderRef),
          transaction.get(receiverRef),
          transaction.get(blockedBySenderRef),
          transaction.get(blockedByReceiverRef),
          transaction.get(chatRef),
          transaction.get(abuseRef),
          transaction.get(messageRef),
        ]);

        activeProfile(senderSnapshot, senderId);
        activeProfile(receiverSnapshot, media.receiverId);
        if (blockedBySender.exists || blockedByReceiver.exists) {
          throw new HttpsError(
            "permission-denied",
            "Messaging is unavailable for this chat.",
          );
        }

        if (existingMessage.exists) {
          const existing = existingMessage.data() || {};
          if (
            existing.senderId === senderId &&
            existing.receiverId === media.receiverId &&
            existing.mediaStoragePath === media.storagePath
          ) {
            return { alreadyCreated: true };
          }
          throw new HttpsError(
            "already-exists",
            "This media message ID is already in use.",
          );
        }

        const existingChat = chatSnapshot.exists ? chatSnapshot.data() : null;
        if (existingChat) {
          const existingParticipants = Array.isArray(existingChat.participants)
            ? [...existingChat.participants].sort()
            : [];
          if (
            existingParticipants.length !== 2 ||
            existingParticipants[0] !== participants[0] ||
            existingParticipants[1] !== participants[1]
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Invalid chat room.",
            );
          }
        }

        const now = admin.firestore.Timestamp.now();
        const nowMs = now.toMillis();
        const abuseData = abuseSnapshot.exists ? abuseSnapshot.data() : {};
        const rate = messageRateDecision({
          nowMs,
          lastMessageAtMs: timestampMillis(abuseData.lastMessageAt),
          windowStartedAtMs: timestampMillis(
            abuseData.messageWindowStartedAt,
          ),
          count: abuseData.messageCount,
        });
        if (!rate.allowed) {
          throw new HttpsError(
            "resource-exhausted",
            "Please slow down before sending more messages.",
            {
              reason: rate.reason,
              retryAfterSeconds: Math.max(
                1,
                Math.ceil(rate.retryAfterMs / 1000),
              ),
            },
          );
        }

        const unreadCounts =
          existingChat && existingChat.unreadCounts
            ? { ...existingChat.unreadCounts }
            : {};
        const readStates =
          existingChat && existingChat.readStates
            ? { ...existingChat.readStates }
            : {};
        const nextReceiverUnread = Number.isInteger(
          unreadCounts[media.receiverId],
        )
          ? unreadCounts[media.receiverId] + 1
          : 1;
        unreadCounts[senderId] = 0;
        unreadCounts[media.receiverId] = nextReceiverUnread;
        readStates[senderId] = {
          ...(readStates[senderId] || {}),
          lastReadAt: now,
          lastReadMessageId: media.messageId,
          unreadCount: 0,
        };
        readStates[media.receiverId] = {
          ...(readStates[media.receiverId] || {}),
          unreadCount: nextReceiverUnread,
        };

        const preview = media.type === "image"
          ? "Photo"
          : media.type === "video"
            ? "Video"
            : "Voice message";
        const chatData = {
          participants,
          lastMessage: preview,
          lastMessageTime: now,
          latestMessageAt: now,
          lastMessageSenderId: senderId,
          latestSenderId: senderId,
          lastMessageId: media.messageId,
          lastMessageType: media.type,
          lastMessageIsUnsent: false,
          unreadCounts,
          readStates,
        };
        if (chatSnapshot.exists) {
          transaction.update(chatRef, chatData);
        } else {
          transaction.set(chatRef, { ...chatData, createdAt: now });
        }

        transaction.set(messageRef, {
          senderId,
          receiverId: media.receiverId,
          text: media.caption,
          timestamp: now,
          isUnsent: false,
          unsentAt: null,
          replyToMessageId: reply && reply.messageId,
          replyToText: reply && reply.text,
          replyToSenderId: reply && reply.senderId,
          type: media.type,
          mediaUrl: null,
          mediaStoragePath: media.storagePath,
          mediaContentType: storedMedia.contentType,
          mediaSizeBytes: storedMedia.sizeBytes,
          mediaDurationMs: media.durationMs,
          downloadAcknowledgements: {
            [senderId]: now,
          },
          isSeen: false,
          seenAt: null,
          deletedFor: [],
        });

        transaction.set(
          abuseRef,
          {
            messageWindowStartedAt: admin.firestore.Timestamp.fromMillis(
              rate.windowStartedAtMs,
            ),
            messageCount: rate.count,
            lastMessageAt: now,
            updatedAt: now,
          },
          { merge: true },
        );

        return { alreadyCreated: false };
      });

      return {
        success: true,
        chatId: media.chatId,
        messageId: media.messageId,
        alreadyCreated: result.alreadyCreated,
      };
    } catch (error) {
      await deleteRejectedUpload(media.storagePath);
      if (error instanceof HttpsError) throw error;
      logger.error("Private media message creation failed", {
        senderId,
        receiverId: media.receiverId,
        messageId: media.messageId,
        error,
      });
      throw new HttpsError(
        "internal",
        "Could not send this media message. Please try again.",
      );
    }
  },
);
