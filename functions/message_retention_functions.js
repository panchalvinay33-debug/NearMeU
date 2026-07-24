"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const {
  RETENTION_POLICY_VERSION,
  privateMediaPathAllowed,
  retentionExpiryMillis,
} = require("./message_retention_logic");

const db = admin.firestore();
const REGION = "asia-south1";
const PURGE_LIMIT = 300;
const MAX_REMAINING_MESSAGES_PER_CHAT = 1000;

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
}

function parentChatReference(messageSnapshot) {
  const chatRef = messageSnapshot.ref.parent.parent;
  if (!chatRef || chatRef.parent.id !== "chats") return null;
  return chatRef;
}

async function deletePrivateMedia(messageSnapshot) {
  const data = messageSnapshot.data() || {};
  const chatRef = parentChatReference(messageSnapshot);
  const storagePath = data.mediaStoragePath;
  if (
    !chatRef ||
    !privateMediaPathAllowed({
      path: storagePath,
      chatId: chatRef.id,
      messageId: messageSnapshot.id,
    })
  ) {
    return false;
  }

  try {
    await admin.storage().bucket().file(storagePath).delete({
      ignoreNotFound: true,
    });
    return true;
  } catch (error) {
    logger.error("Expired private media deletion failed", {
      chatId: chatRef.id,
      messageId: messageSnapshot.id,
      error,
    });
    return false;
  }
}

async function refreshChatMetadata(chatRef) {
  const chatSnapshot = await chatRef.get();
  if (!chatSnapshot.exists) return;

  const chatData = chatSnapshot.data() || {};
  const participants = Array.isArray(chatData.participants)
    ? chatData.participants.filter((value) => typeof value === "string")
    : [];
  if (participants.length !== 2) return;

  const remaining = await chatRef
    .collection("messages")
    .orderBy("timestamp", "desc")
    .limit(MAX_REMAINING_MESSAGES_PER_CHAT)
    .get();
  const unreadCounts = Object.fromEntries(
    participants.map((participant) => [participant, 0]),
  );

  for (const message of remaining.docs) {
    const data = message.data() || {};
    const receiverId = data.receiverId;
    if (
      data.isSeen !== true &&
      typeof receiverId === "string" &&
      Object.hasOwn(unreadCounts, receiverId)
    ) {
      unreadCounts[receiverId] += 1;
    }
  }

  const oldReadStates =
    chatData.readStates && typeof chatData.readStates === "object"
      ? chatData.readStates
      : {};
  const readStates = {};
  for (const participant of participants) {
    const oldState =
      oldReadStates[participant] && typeof oldReadStates[participant] === "object"
        ? oldReadStates[participant]
        : {};
    readStates[participant] = {
      ...oldState,
      unreadCount: unreadCounts[participant],
    };
  }

  if (remaining.empty) {
    await chatRef.set(
      {
        lastMessage: "Message history is stored on your device",
        lastMessageTime: null,
        latestMessageAt: null,
        lastMessageSenderId: null,
        latestSenderId: null,
        lastMessageType: "expired",
        lastMessageIsUnsent: false,
        unreadCounts,
        readStates,
        cloudHistoryExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return;
  }

  const latest = remaining.docs[0];
  const latestData = latest.data() || {};
  const isUnsent = latestData.isUnsent === true;
  const type = typeof latestData.type === "string" ? latestData.type : "text";
  const fallbackText = type === "image" ? "Photo" : type === "video" ? "Video" : "Message";
  const text = isUnsent
    ? "This message was unsent"
    : typeof latestData.text === "string" && latestData.text.trim()
      ? latestData.text.trim()
      : fallbackText;

  await chatRef.set(
    {
      lastMessage: text,
      lastMessageTime: latestData.timestamp || null,
      latestMessageAt: latestData.timestamp || null,
      lastMessageSenderId: latestData.senderId || null,
      latestSenderId: latestData.senderId || null,
      lastMessageType: type,
      lastMessageIsUnsent: isUnsent,
      unreadCounts,
      readStates,
      lastMessageId: latest.id,
      cloudHistoryExpiredAt: admin.firestore.FieldValue.delete(),
    },
    { merge: true },
  );
}

exports.stampPrivateMessageRetention = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data() || {};
    if (
      timestampMillis(data.cloudExpiresAt) !== null &&
      data.retentionPolicyVersion === RETENTION_POLICY_VERSION
    ) {
      return;
    }

    const sourceTimestampMs =
      timestampMillis(data.timestamp) || Date.parse(event.time || "") || Date.now();
    await snapshot.ref.set(
      {
        cloudExpiresAt: admin.firestore.Timestamp.fromMillis(
          retentionExpiryMillis(sourceTimestampMs),
        ),
        retentionPolicyVersion: RETENTION_POLICY_VERSION,
      },
      { merge: true },
    );
  },
);

exports.purgeExpiredPrivateMessages = onSchedule(
  {
    schedule: "every 60 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const expired = await db
      .collectionGroup("messages")
      .where("cloudExpiresAt", "<=", now)
      .orderBy("cloudExpiresAt", "asc")
      .limit(PURGE_LIMIT)
      .get();
    if (expired.empty) return;

    const touchedChats = new Map();
    let mediaDeleted = 0;
    for (const message of expired.docs) {
      const chatRef = parentChatReference(message);
      if (chatRef) touchedChats.set(chatRef.path, chatRef);
      if (await deletePrivateMedia(message)) mediaDeleted += 1;
    }

    const batch = db.batch();
    for (const message of expired.docs) batch.delete(message.ref);
    await batch.commit();

    for (const chatRef of touchedChats.values()) {
      try {
        await refreshChatMetadata(chatRef);
      } catch (error) {
        logger.error("Chat metadata refresh after retention purge failed", {
          chatId: chatRef.id,
          error,
        });
      }
    }

    logger.info("Expired private messages purged", {
      messageCount: expired.size,
      mediaDeleted,
      chatCount: touchedChats.size,
    });
  },
);

module.exports.refreshChatMetadata = refreshChatMetadata;
