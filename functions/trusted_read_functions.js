"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const {
  firstVisiblePreviewMessage,
  isFreshOnlinePresence,
  mergeChatDocuments,
  shouldScanLegacyChats,
} = require("./trusted_read_logic");

const db = admin.firestore();
const REGION = "asia-south1";
const MAX_CHAT_PREVIEWS = 100;
const MAX_LEGACY_MESSAGES = 100;
const MAX_DISCOVERY_USERS = 100;
const MAX_PREVIEW_MESSAGE_SCAN = 50;
const MAX_CHAT_DOCUMENTS_TO_INSPECT =
  MAX_CHAT_PREVIEWS + MAX_LEGACY_MESSAGES;

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  return uid;
}

function requireActiveProfile(snapshot, uid) {
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

function safeString(value, fallback = "") {
  return typeof value === "string" ? value : fallback;
}

function safeInteger(value, fallback = 0) {
  return Number.isInteger(value) ? value : fallback;
}

function safeMap(value) {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value
    : {};
}

function canonicalParticipants(firstId, secondId) {
  return [firstId, secondId].sort();
}

function validParticipants(value, uid) {
  return (
    Array.isArray(value) &&
    value.length === 2 &&
    value.every((participant) => typeof participant === "string") &&
    value[0] !== value[1] &&
    value.includes(uid)
  );
}

function participantsFromMessage(message, uid) {
  const senderId = safeString(message.senderId);
  const receiverId = safeString(message.receiverId);
  if (!senderId || !receiverId || senderId === receiverId) return null;
  if (senderId !== uid && receiverId !== uid) return null;
  return canonicalParticipants(senderId, receiverId);
}

function publicUserPayload(snapshot) {
  const data = snapshot.data() || {};
  return {
    uid: snapshot.id,
    nickname: safeString(data.nickname, "NearMeU user"),
    gender: safeString(data.gender),
    lookingFor: safeString(data.lookingFor),
    approxLatitude:
      typeof data.approxLatitude === "number" ? data.approxLatitude : null,
    approxLongitude:
      typeof data.approxLongitude === "number" ? data.approxLongitude : null,
    locationCell: safeString(data.locationCell),
    discoveryCells: Array.isArray(data.discoveryCells)
      ? data.discoveryCells.filter((value) => typeof value === "string")
      : [],
    state: typeof data.state === "string" ? data.state : null,
    country: typeof data.country === "string" ? data.country : null,
    photoUrl: typeof data.photoUrl === "string" ? data.photoUrl : null,
    age: safeInteger(data.age, 18),
    lastSeenMillis: timestampMillis(data.lastSeen),
    createdAtMillis: timestampMillis(data.createdAt),
    isOnline: data.isOnline === true,
    isAdmin: data.isAdmin === true,
    isSuspended: data.isSuspended === true,
    privacyVersion: safeInteger(data.privacyVersion, 0),
  };
}

async function legacyChatDocuments(uid) {
  const [sentMessages, receivedMessages] = await Promise.all([
    db
      .collectionGroup("messages")
      .where("senderId", "==", uid)
      .limit(MAX_LEGACY_MESSAGES)
      .get(),
    db
      .collectionGroup("messages")
      .where("receiverId", "==", uid)
      .limit(MAX_LEGACY_MESSAGES)
      .get(),
  ]);

  const references = new Map();
  for (const message of [...sentMessages.docs, ...receivedMessages.docs]) {
    const chatRef = message.ref.parent.parent;
    if (chatRef) references.set(chatRef.path, chatRef);
    if (references.size >= MAX_CHAT_PREVIEWS) break;
  }

  if (!references.size) return [];
  return db.getAll(...references.values());
}

async function repairLegacyChat({
  chatDocument,
  data,
  participants,
  latestMessageId,
  latestData,
}) {
  const lastMessageTime =
    data.lastMessageTime || latestData.timestamp || admin.firestore.Timestamp.now();
  const isUnsent =
    latestData.isUnsent === true ||
    data.lastMessageIsUnsent === true ||
    data.lastMessage === "This message was unsent";
  const lastMessage = isUnsent
    ? "This message was unsent"
    : safeString(data.lastMessage, safeString(latestData.text, "Message"));
  const lastSenderId = safeString(
    data.lastMessageSenderId,
    safeString(latestData.senderId),
  );
  const existingUnreadCounts = safeMap(data.unreadCounts);
  const existingReadStates = safeMap(data.readStates);
  const unreadCounts = {};
  const readStates = {};

  for (const participant of participants) {
    unreadCounts[participant] = safeInteger(existingUnreadCounts[participant], 0);
    const existingState = safeMap(existingReadStates[participant]);
    readStates[participant] = {
      ...existingState,
      unreadCount: safeInteger(
        existingState.unreadCount,
        unreadCounts[participant],
      ),
    };
  }

  await chatDocument.ref.set(
    {
      participants,
      lastMessage,
      lastMessageTime,
      latestMessageAt: data.latestMessageAt || lastMessageTime,
      lastMessageSenderId: lastSenderId,
      latestSenderId: safeString(data.latestSenderId, lastSenderId),
      lastMessageType: safeString(
        latestData.type,
        safeString(data.lastMessageType, "text"),
      ),
      lastMessageIsUnsent: isUnsent,
      createdAt: data.createdAt || lastMessageTime,
      unreadCounts,
      readStates,
      legacyRepair: {
        repairedAt: admin.firestore.FieldValue.serverTimestamp(),
        sourceMessageId: latestMessageId,
      },
    },
    { merge: true },
  );
}

function fallbackPreviewText(message) {
  const text = safeString(message.text).trim();
  if (text) return text;
  const type = safeString(message.type, "text");
  if (type === "image") return "Photo";
  if (type === "video") return "Video";
  if (type === "audio" || type === "voice") return "Voice message";
  return "Message";
}

async function buildChatPreview({
  chatDocument,
  uid,
  currentUserRef,
  allowRepair,
}) {
  const data = chatDocument.data() || {};
  const messageSnapshot = await chatDocument.ref
    .collection("messages")
    .orderBy("timestamp", "desc")
    .limit(MAX_PREVIEW_MESSAGE_SCAN)
    .get();
  if (messageSnapshot.empty) return null;

  const latestMessage = messageSnapshot.docs[0];
  const latestData = latestMessage.data() || {};
  const existingParticipants = validParticipants(data.participants, uid)
    ? data.participants
    : null;
  const participants =
    existingParticipants || participantsFromMessage(latestData, uid);
  if (!participants) return null;

  const otherUserId = participants.find((value) => value !== uid);
  if (!otherUserId) return null;

  const otherUserRef = db.collection("users").doc(otherUserId);
  const blockedByCurrentRef = currentUserRef
    .collection("blocks")
    .doc(otherUserId);
  const blockedByOtherRef = otherUserRef.collection("blocks").doc(uid);
  const [otherUser, blockedByCurrent, blockedByOther] = await Promise.all([
    otherUserRef.get(),
    blockedByCurrentRef.get(),
    blockedByOtherRef.get(),
  ]);

  if (blockedByCurrent.exists || blockedByOther.exists) return null;

  const otherData = otherUser.exists ? otherUser.data() || {} : {};
  if (otherData.isSuspended === true) return null;

  const needsRepair =
    !existingParticipants ||
    !data.lastMessageTime ||
    !data.lastMessageSenderId ||
    !data.unreadCounts ||
    !data.readStates;
  if (allowRepair && needsRepair) {
    await repairLegacyChat({
      chatDocument,
      data,
      participants,
      latestMessageId: latestMessage.id,
      latestData,
    });
  }

  const unreadCounts = safeMap(data.unreadCounts);
  const readStates = safeMap(data.readStates);
  const currentReadState = safeMap(readStates[uid]);
  const clearStates = safeMap(data.clearStates);
  const currentClearState = safeMap(clearStates[uid]);
  const clearedAtMillis = timestampMillis(currentClearState.clearedAt);

  const candidates = messageSnapshot.docs.map((document) => {
    const message = document.data() || {};
    return {
      id: document.id,
      data: message,
      deletedFor: Array.isArray(message.deletedFor) ? message.deletedFor : [],
      messageTimeMillis: timestampMillis(message.timestamp),
    };
  });
  const visible = firstVisiblePreviewMessage(candidates, uid, clearedAtMillis);
  const visibleData = visible ? visible.data : null;
  const visibleIsLatest = visible && visible.id === latestMessage.id;
  const isUnsent = visibleData ? visibleData.isUnsent === true : false;
  const lastMessage = !visibleData
    ? ""
    : isUnsent
      ? "This message was unsent"
      : visibleIsLatest && typeof data.lastMessage === "string"
        ? data.lastMessage
        : fallbackPreviewText(visibleData);
  const lastMessageTime = visibleData ? visibleData.timestamp : null;
  const lastSenderId = visibleData ? safeString(visibleData.senderId) : "";

  return {
    chatId: chatDocument.id,
    otherUserId,
    otherUserName: otherUser.exists
      ? safeString(otherData.nickname, "NearMeU user")
      : "Unavailable user",
    otherUserPhotoUrl:
      typeof otherData.photoUrl === "string" ? otherData.photoUrl : null,
    lastMessage,
    lastMessageTimeMillis: timestampMillis(lastMessageTime),
    messageType: visibleData ? safeString(visibleData.type, "text") : "text",
    isUnsent,
    lastMessageSenderId: lastSenderId || null,
    lastMessageSeen:
      visibleData && typeof visibleData.isSeen === "boolean"
        ? visibleData.isSeen
        : null,
    unreadCount: visibleData
      ? Number.isInteger(unreadCounts[uid])
        ? unreadCounts[uid]
        : safeInteger(currentReadState.unreadCount, 0)
      : 0,
    isOtherUserOnline: isFreshOnlinePresence({
      isOnline: otherData.isOnline === true,
      lastSeenMillis: timestampMillis(otherData.lastSeen),
    }),
  };
}

exports.getPrivateChatPreviews = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const currentUserRef = db.collection("users").doc(uid);
    const currentUser = await currentUserRef.get();
    requireActiveProfile(currentUser, uid);

    const chatsSnapshot = await db
      .collection("chats")
      .where("participants", "array-contains", uid)
      .limit(MAX_CHAT_PREVIEWS)
      .get();

    const normalDocuments = chatsSnapshot.docs;
    const legacyDocuments = shouldScanLegacyChats(
      normalDocuments.length,
      MAX_CHAT_PREVIEWS,
    )
      ? await legacyChatDocuments(uid)
      : [];
    const chatDocuments = mergeChatDocuments({
      normalDocuments,
      legacyDocuments,
      maximumDocuments: MAX_CHAT_DOCUMENTS_TO_INSPECT,
    });

    const previews = await Promise.all(
      chatDocuments.map((chatDocument) =>
        buildChatPreview({
          chatDocument,
          uid,
          currentUserRef,
          allowRepair: true,
        }),
      ),
    );

    const chats = previews
      .filter((value) => value !== null)
      .sort((first, second) => {
        const firstTime = first.lastMessageTimeMillis || 0;
        const secondTime = second.lastMessageTimeMillis || 0;
        if (firstTime !== secondTime) return secondTime - firstTime;
        return first.chatId.localeCompare(second.chatId);
      })
      .slice(0, MAX_CHAT_PREVIEWS);

    return {
      chats,
      repairedLegacyChats: legacyDocuments.length > 0,
    };
  },
);

exports.getNearbyCandidates = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const currentUserRef = db.collection("users").doc(uid);
    const [currentUser, ownBlocks, usersSnapshot] = await Promise.all([
      currentUserRef.get(),
      currentUserRef.collection("blocks").get(),
      db.collection("users").limit(MAX_DISCOVERY_USERS).get(),
    ]);

    requireActiveProfile(currentUser, uid);

    const blockedByCurrent = new Set(ownBlocks.docs.map((document) => document.id));
    const candidates = usersSnapshot.docs.filter((document) => {
      if (document.id === uid || blockedByCurrent.has(document.id)) return false;
      const data = document.data() || {};
      return (
        data.isSuspended !== true &&
        Number.isInteger(data.age) &&
        data.age >= 18
      );
    });

    const incomingBlockRefs = candidates.map((document) =>
      document.ref.collection("blocks").doc(uid),
    );
    const incomingBlocks = incomingBlockRefs.length
      ? await db.getAll(...incomingBlockRefs)
      : [];

    const users = candidates
      .filter((_, index) => !incomingBlocks[index].exists)
      .map(publicUserPayload);

    return { users };
  },
);
