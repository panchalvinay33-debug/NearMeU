"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const {
  normalizeDownloadAcknowledgement,
} = require("./private_media_logic");
const {
  privateMediaPathAllowed,
} = require("./message_retention_logic");

const db = admin.firestore();
const REGION = "asia-south1";
const DOWNLOAD_ACK_VERSION = 1;

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

exports.acknowledgePrivateMediaDownload = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    let acknowledgement;
    try {
      acknowledgement = normalizeDownloadAcknowledgement(request.data);
    } catch (error) {
      throw new HttpsError("invalid-argument", error.message);
    }

    const chatRef = db.collection("chats").doc(acknowledgement.chatId);
    const messageRef = chatRef
      .collection("messages")
      .doc(acknowledgement.messageId);

    const media = await db.runTransaction(async (transaction) => {
      const [chatSnapshot, messageSnapshot] = await Promise.all([
        transaction.get(chatRef),
        transaction.get(messageRef),
      ]);
      if (!chatSnapshot.exists || !messageSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "This media message is no longer available in the cloud.",
        );
      }

      const chat = chatSnapshot.data() || {};
      const message = messageSnapshot.data() || {};
      const participants = Array.isArray(chat.participants)
        ? chat.participants
        : [];
      if (!participants.includes(uid) || message.receiverId !== uid) {
        throw new HttpsError(
          "permission-denied",
          "Only the receiving user can confirm this download.",
        );
      }
      if (
        message.type !== "image" &&
        message.type !== "video" &&
        message.type !== "voice"
      ) {
        throw new HttpsError(
          "failed-precondition",
          "This message does not contain downloadable media.",
        );
      }

      const storagePath = message.mediaStoragePath;
      if (
        !privateMediaPathAllowed({
          path: storagePath,
          senderId: message.senderId,
          chatId: acknowledgement.chatId,
          messageId: acknowledgement.messageId,
        })
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Private media storage metadata is invalid.",
        );
      }

      const acknowledgements =
        message.downloadAcknowledgements &&
        typeof message.downloadAcknowledgements === "object"
          ? message.downloadAcknowledgements
          : {};
      const alreadyAcknowledged = acknowledgements[uid] != null;
      if (!alreadyAcknowledged) {
        const now = admin.firestore.Timestamp.now();
        transaction.update(
          messageRef,
          new admin.firestore.FieldPath("downloadAcknowledgements", uid),
          now,
          "downloadAcknowledgementVersion",
          DOWNLOAD_ACK_VERSION,
          "recipientDownloadedAt",
          now,
        );
      }

      return {
        storagePath,
        alreadyAcknowledged,
        cloudMediaDeletedAt: message.cloudMediaDeletedAt || null,
      };
    });

    if (media.cloudMediaDeletedAt) {
      return {
        success: true,
        alreadyAcknowledged: true,
        cloudMediaDeleted: true,
      };
    }

    try {
      await admin.storage().bucket().file(media.storagePath).delete({
        ignoreNotFound: true,
      });
    } catch (error) {
      logger.error("Recipient download was saved but cloud media cleanup failed", {
        uid,
        chatId: acknowledgement.chatId,
        messageId: acknowledgement.messageId,
        error,
      });
      throw new HttpsError(
        "unavailable",
        "Download was saved. Cloud cleanup will be retried.",
      );
    }

    try {
      await messageRef.set(
        {
          cloudMediaDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
          cloudMediaDeleteReason: "recipient_downloaded",
        },
        { merge: true },
      );
    } catch (error) {
      logger.warn("Cloud media deleted before acknowledgement audit update", {
        uid,
        chatId: acknowledgement.chatId,
        messageId: acknowledgement.messageId,
        error,
      });
    }

    return {
      success: true,
      alreadyAcknowledged: media.alreadyAcknowledged,
      cloudMediaDeleted: true,
    };
  },
);
