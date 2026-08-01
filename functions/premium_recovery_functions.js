"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const {
  readPremiumEntitlement,
  requirePremiumEntitlement,
} = require("./premium_entitlement_functions");
const {
  RECOVERY_POLICY_VERSION,
  recoveryDecision,
  recoveryMediaPath,
} = require("./premium_recovery_logic");

const db = admin.firestore();
const REGION = "asia-south1";
const PURGE_LIMIT = 250;
const RESTORE_PAGE_LIMIT = 100;
const CHAT_PURGE_PAGE_LIMIT = 200;

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
}

function recoveryUserRef(uid) {
  return db.collection("premiumRecoveryUsers").doc(uid);
}

function recoveryChatRef(uid, chatId) {
  return recoveryUserRef(uid).collection("chats").doc(chatId);
}

function recoveryMessageRef(uid, chatId, messageId) {
  return recoveryChatRef(uid, chatId).collection("messages").doc(messageId);
}

function clearCutoffMillis(chatData, uid) {
  const clearStates = chatData && typeof chatData.clearStates === "object"
    ? chatData.clearStates
    : {};
  const state = clearStates && typeof clearStates[uid] === "object"
    ? clearStates[uid]
    : null;
  return timestampMillis(state && state.clearedAt);
}

function normalizedParticipants(chatData) {
  return Array.isArray(chatData && chatData.participants)
    ? chatData.participants.filter((uid) => typeof uid === "string" && uid)
    : [];
}

function recoveryMediaPathAllowed(path, uid, chatId, messageId) {
  return typeof path === "string" && path.startsWith(
    `premiumRecoveryMedia/${uid}/${chatId}/${messageId}/`,
  );
}

async function copyRecoveryMedia({ uid, chatId, messageId, sourcePath }) {
  if (typeof sourcePath !== "string" || !sourcePath) return null;
  const destinationPath = recoveryMediaPath({ uid, chatId, messageId, sourcePath });
  const bucket = admin.storage().bucket();
  const source = bucket.file(sourcePath);
  const destination = bucket.file(destinationPath);
  const [sourceExists] = await source.exists();
  if (!sourceExists) throw new Error(`Recovery source media is missing: ${sourcePath}`);
  const [destinationExists] = await destination.exists();
  if (!destinationExists) await source.copy(destination);
  return destinationPath;
}

async function deleteRecoveryMedia({ uid, chatId, messageId, path }) {
  if (!path) return;
  if (!recoveryMediaPathAllowed(path, uid, chatId, messageId)) {
    logger.error("Recovery media path failed safety validation", {
      uid,
      chatId,
      messageId,
      path,
    });
    return;
  }
  await admin.storage().bucket().file(path).delete({ ignoreNotFound: true });
}

async function deleteRecoveryMessageForUser({ uid, chatId, messageId }) {
  const ref = recoveryMessageRef(uid, chatId, messageId);
  const snapshot = await ref.get();
  if (!snapshot.exists) return false;
  const data = snapshot.data() || {};
  await deleteRecoveryMedia({
    uid,
    chatId,
    messageId,
    path: data.recoveryMediaStoragePath,
  });
  await ref.delete();
  return true;
}

async function writeRecoveryCopy({ uid, chatId, messageId, chatData, messageData }) {
  const entitlement = await readPremiumEntitlement(uid);
  const timestampMs = timestampMillis(messageData.timestamp);
  const decision = recoveryDecision({
    uid,
    entitlement,
    clearCutoffMs: clearCutoffMillis(chatData, uid),
    message: { ...messageData, timestampMs },
  });
  if (!decision.eligible) return { written: false, reason: decision.reason };

  const type = typeof messageData.type === "string" ? messageData.type : "text";
  const isMedia = type !== "text";
  if (isMedia && uid === messageData.receiverId) {
    const acknowledgements = messageData.downloadAcknowledgements &&
      typeof messageData.downloadAcknowledgements === "object"
      ? messageData.downloadAcknowledgements
      : {};
    if (acknowledgements[uid] == null) {
      return { written: false, reason: "receiver-media-not-downloaded" };
    }
  }

  const recoveryMediaStoragePath = await copyRecoveryMedia({
    uid,
    chatId,
    messageId,
    sourcePath: messageData.mediaStoragePath,
  });
  const recoveryExpiresAt = admin.firestore.Timestamp.fromMillis(
    decision.recoveryExpiresAtMs,
  );
  const assignedAt = admin.firestore.Timestamp.now();
  const messageRef = recoveryMessageRef(uid, chatId, messageId);
  const chatRef = recoveryChatRef(uid, chatId);

  const batch = db.batch();
  batch.set(messageRef, {
    ownerId: uid,
    chatId,
    messageId,
    senderId: messageData.senderId || null,
    receiverId: messageData.receiverId || null,
    text: typeof messageData.text === "string" ? messageData.text : "",
    timestamp: messageData.timestamp,
    type,
    replyToMessageId: messageData.replyToMessageId || null,
    replyToText: messageData.replyToText || null,
    replyToSenderId: messageData.replyToSenderId || null,
    mediaContentType: messageData.mediaContentType || null,
    mediaSizeBytes: messageData.mediaSizeBytes || null,
    mediaDurationMs: messageData.mediaDurationMs || null,
    recoveryMediaStoragePath,
    recoveryAssignedAt: assignedAt,
    recoveryExpiresAt,
    recoveryPolicyVersion: RECOVERY_POLICY_VERSION,
    sourceMessagePath: `chats/${chatId}/messages/${messageId}`,
  }, { merge: true });
  batch.set(chatRef, {
    ownerId: uid,
    chatId,
    participants: normalizedParticipants(chatData),
    latestRecoveryTimestamp: messageData.timestamp,
    updatedAt: assignedAt,
    recoveryPolicyVersion: RECOVERY_POLICY_VERSION,
  }, { merge: true });
  batch.set(recoveryUserRef(uid), {
    ownerId: uid,
    updatedAt: assignedAt,
    recoveryPolicyVersion: RECOVERY_POLICY_VERSION,
  }, { merge: true });
  await batch.commit();
  return { written: true, reason: "eligible" };
}

async function purgeRecoveryChatForUser({ uid, chatId }) {
  const chatRef = recoveryChatRef(uid, chatId);
  let cursor = null;
  let deleted = 0;
  while (true) {
    let query = chatRef.collection("messages")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(CHAT_PURGE_PAGE_LIMIT);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) break;
    for (const message of snapshot.docs) {
      const data = message.data() || {};
      await deleteRecoveryMedia({
        uid,
        chatId,
        messageId: message.id,
        path: data.recoveryMediaStoragePath,
      });
    }
    const batch = db.batch();
    for (const message of snapshot.docs) batch.delete(message.ref);
    await batch.commit();
    deleted += snapshot.size;
    cursor = snapshot.docs[snapshot.docs.length - 1];
  }
  await chatRef.delete().catch(() => {});
  return deleted;
}

exports.capturePremiumRecoveryOnMessageCreate = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: REGION,
    retry: true,
    timeoutSeconds: 180,
    memory: "512MiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const chatRef = snapshot.ref.parent.parent;
    if (!chatRef) return;
    const chatSnapshot = await chatRef.get();
    if (!chatSnapshot.exists) return;
    const chatData = chatSnapshot.data() || {};
    const participants = normalizedParticipants(chatData);
    if (participants.length !== 2) return;
    const messageData = snapshot.data() || {};

    const outcomes = await Promise.all(participants.map(async (uid) => {
      try {
        return await writeRecoveryCopy({ uid, chatId, messageId, chatData, messageData });
      } catch (error) {
        logger.error("Premium recovery capture failed", { uid, chatId, messageId, error });
        throw error;
      }
    }));

    logger.info("Premium recovery capture processed", { chatId, messageId, outcomes });
  },
);

exports.syncPremiumRecoveryOnMessageUpdate = onDocumentUpdated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: REGION,
    retry: true,
    timeoutSeconds: 180,
    memory: "512MiB",
  },
  async (event) => {
    const beforeSnapshot = event.data && event.data.before;
    const afterSnapshot = event.data && event.data.after;
    if (!beforeSnapshot || !afterSnapshot) return;
    const before = beforeSnapshot.data() || {};
    const after = afterSnapshot.data() || {};
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const chatRef = afterSnapshot.ref.parent.parent;
    if (!chatRef) return;
    const chatSnapshot = await chatRef.get();
    const chatData = chatSnapshot.exists ? chatSnapshot.data() || {} : {};
    const participants = normalizedParticipants(chatData);

    if (after.isUnsent === true && before.isUnsent !== true) {
      await Promise.all(participants.map((uid) =>
        deleteRecoveryMessageForUser({ uid, chatId, messageId }),
      ));
      return;
    }

    const beforeDeleted = new Set(Array.isArray(before.deletedFor) ? before.deletedFor : []);
    const afterDeleted = new Set(Array.isArray(after.deletedFor) ? after.deletedFor : []);
    const newlyDeleted = [...afterDeleted].filter((uid) => !beforeDeleted.has(uid));
    if (newlyDeleted.length > 0) {
      await Promise.all(newlyDeleted.map((uid) =>
        deleteRecoveryMessageForUser({ uid, chatId, messageId }),
      ));
    }

    const receiverId = after.receiverId;
    const type = typeof after.type === "string" ? after.type : "text";
    if (type !== "text" && typeof receiverId === "string" && receiverId) {
      const beforeAcks = before.downloadAcknowledgements &&
        typeof before.downloadAcknowledgements === "object"
        ? before.downloadAcknowledgements
        : {};
      const afterAcks = after.downloadAcknowledgements &&
        typeof after.downloadAcknowledgements === "object"
        ? after.downloadAcknowledgements
        : {};
      if (beforeAcks[receiverId] == null && afterAcks[receiverId] != null) {
        await writeRecoveryCopy({
          uid: receiverId,
          chatId,
          messageId,
          chatData,
          messageData: after,
        });
      }
    }
  },
);

exports.getMyPremiumRecoveryPage = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
    const entitlement = await readPremiumEntitlement(uid);
    requirePremiumEntitlement(entitlement, "premium-recovery");

    const chatId = request.data && request.data.chatId;
    if (typeof chatId !== "string" || !chatId || chatId.length > 200) {
      throw new HttpsError("invalid-argument", "A valid chatId is required.");
    }

    const liveChatSnapshot = await db.collection("chats").doc(chatId).get();
    if (!liveChatSnapshot.exists) {
      throw new HttpsError("not-found", "This chat is no longer available.");
    }
    const liveChatData = liveChatSnapshot.data() || {};
    const liveParticipants = normalizedParticipants(liveChatData);
    if (liveParticipants.length !== 2 || !liveParticipants.includes(uid)) {
      throw new HttpsError("permission-denied", "Invalid private chat.");
    }
    const authoritativeClearCutoffMs = clearCutoffMillis(liveChatData, uid);

    const requestedLimit = Number.isInteger(request.data && request.data.limit)
      ? request.data.limit
      : RESTORE_PAGE_LIMIT;
    const limit = Math.max(1, Math.min(RESTORE_PAGE_LIMIT, requestedLimit));
    const afterMillis = Number.isFinite(request.data && request.data.afterMillis)
      ? Math.trunc(request.data.afterMillis)
      : null;
    const afterMessageId = typeof (request.data && request.data.afterMessageId) === "string"
      ? request.data.afterMessageId
      : null;
    if ((afterMillis === null) !== (afterMessageId === null)) {
      throw new HttpsError("invalid-argument", "Recovery cursor is incomplete.");
    }

    let query = recoveryChatRef(uid, chatId).collection("messages");
    if (authoritativeClearCutoffMs !== null) {
      query = query.where(
        "timestamp",
        ">",
        admin.firestore.Timestamp.fromMillis(authoritativeClearCutoffMs),
      );
    }
    query = query
      .orderBy("timestamp", "asc")
      .orderBy(admin.firestore.FieldPath.documentId(), "asc")
      .limit(limit);
    if (afterMillis !== null) {
      query = query.startAfter(
        admin.firestore.Timestamp.fromMillis(afterMillis),
        afterMessageId,
      );
    }

    const snapshot = await query.get();
    const messages = snapshot.docs.map((doc) => {
      const data = doc.data() || {};
      return {
        messageId: doc.id,
        senderId: data.senderId || null,
        receiverId: data.receiverId || null,
        text: typeof data.text === "string" ? data.text : "",
        timestampMillis: timestampMillis(data.timestamp),
        type: data.type || "text",
        replyToMessageId: data.replyToMessageId || null,
        replyToText: data.replyToText || null,
        replyToSenderId: data.replyToSenderId || null,
        mediaContentType: data.mediaContentType || null,
        mediaSizeBytes: data.mediaSizeBytes || null,
        mediaDurationMs: data.mediaDurationMs || null,
        recoveryMediaStoragePath: data.recoveryMediaStoragePath || null,
        recoveryExpiresAtMillis: timestampMillis(data.recoveryExpiresAt),
      };
    });
    const last = snapshot.docs.length > 0
      ? snapshot.docs[snapshot.docs.length - 1]
      : null;
    const lastData = last ? last.data() || {} : {};
    return {
      chatId,
      messages,
      hasMore: snapshot.size === limit,
      nextAfterMillis: last ? timestampMillis(lastData.timestamp) : null,
      nextAfterMessageId: last ? last.id : null,
      clearCutoffMillis: authoritativeClearCutoffMs,
    };
  },
);

exports.purgeExpiredPremiumRecovery = onSchedule(
  {
    schedule: "every 60 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await db.collectionGroup("messages")
      .where("recoveryExpiresAt", "<=", now)
      .orderBy("recoveryExpiresAt", "asc")
      .limit(PURGE_LIMIT)
      .get();
    if (snapshot.empty) return;

    let deleted = 0;
    for (const message of snapshot.docs) {
      const data = message.data() || {};
      const uid = data.ownerId;
      const chatId = data.chatId;
      const messageId = data.messageId || message.id;
      if (typeof uid !== "string" || typeof chatId !== "string") {
        logger.error("Invalid Premium recovery record skipped", { path: message.ref.path });
        continue;
      }
      await deleteRecoveryMedia({
        uid,
        chatId,
        messageId,
        path: data.recoveryMediaStoragePath,
      });
      await message.ref.delete();
      deleted += 1;
    }
    logger.info("Expired Premium recovery purge complete", {
      queried: snapshot.size,
      deleted,
    });
  },
);

Object.defineProperties(module.exports, {
  purgeRecoveryChatForUser: {
    value: purgeRecoveryChatForUser,
    enumerable: false,
  },
  deleteRecoveryMessageForUser: {
    value: deleteRecoveryMessageForUser,
    enumerable: false,
  },
});
