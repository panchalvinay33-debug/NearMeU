"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const db = admin.firestore();
const REGION = "asia-south1";
const MAX_CHAT_PREVIEWS = 100;
const MAX_DISCOVERY_USERS = 100;

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

    const previews = await Promise.all(
      chatsSnapshot.docs.map(async (chatDocument) => {
        const data = chatDocument.data() || {};
        const participants = Array.isArray(data.participants)
          ? data.participants.filter((value) => typeof value === "string")
          : [];

        if (participants.length !== 2 || !participants.includes(uid)) {
          return null;
        }

        const otherUserId = participants.find((value) => value !== uid);
        if (!otherUserId) return null;

        const otherUserRef = db.collection("users").doc(otherUserId);
        const blockedByCurrentRef = currentUserRef
          .collection("blocks")
          .doc(otherUserId);
        const blockedByOtherRef = otherUserRef.collection("blocks").doc(uid);

        const [otherUser, blockedByCurrent, blockedByOther, latestMessages] =
          await Promise.all([
            otherUserRef.get(),
            blockedByCurrentRef.get(),
            blockedByOtherRef.get(),
            chatDocument.ref
              .collection("messages")
              .orderBy("timestamp", "desc")
              .limit(1)
              .get(),
          ]);

        if (blockedByCurrent.exists || blockedByOther.exists) return null;

        const otherData = otherUser.exists ? otherUser.data() || {} : {};
        if (otherData.isSuspended === true) return null;

        const unreadCounts =
          data.unreadCounts && typeof data.unreadCounts === "object"
            ? data.unreadCounts
            : {};
        const readStates =
          data.readStates && typeof data.readStates === "object"
            ? data.readStates
            : {};
        const currentReadState =
          readStates[uid] && typeof readStates[uid] === "object"
            ? readStates[uid]
            : {};

        let lastMessageSeen = null;
        let messageType = safeString(data.lastMessageType, "text");
        let isUnsent =
          data.lastMessageIsUnsent === true ||
          data.lastMessage === "This message was unsent";

        if (!latestMessages.empty) {
          const latestData = latestMessages.docs[0].data() || {};
          messageType = safeString(latestData.type, messageType);
          isUnsent = latestData.isUnsent === true || isUnsent;
          lastMessageSeen =
            typeof latestData.isSeen === "boolean" ? latestData.isSeen : null;
        }

        return {
          chatId: chatDocument.id,
          otherUserId,
          otherUserName: otherUser.exists
            ? safeString(otherData.nickname, "NearMeU user")
            : "Unavailable user",
          lastMessage: safeString(data.lastMessage),
          lastMessageTimeMillis: timestampMillis(data.lastMessageTime),
          messageType,
          isUnsent,
          lastMessageSenderId:
            typeof data.lastMessageSenderId === "string"
              ? data.lastMessageSenderId
              : null,
          lastMessageSeen,
          unreadCount: Number.isInteger(unreadCounts[uid])
            ? unreadCounts[uid]
            : safeInteger(currentReadState.unreadCount, 0),
          isOtherUserOnline: otherData.isOnline === true,
        };
      }),
    );

    const chats = previews
      .filter((value) => value !== null)
      .sort((first, second) => {
        const firstTime = first.lastMessageTimeMillis || 0;
        const secondTime = second.lastMessageTimeMillis || 0;
        if (firstTime !== secondTime) return secondTime - firstTime;
        return first.chatId.localeCompare(second.chatId);
      });

    return { chats };
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
