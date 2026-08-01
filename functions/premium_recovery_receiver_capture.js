"use strict";

const admin = require("firebase-admin");

const {
  readPremiumEntitlement,
} = require("./premium_entitlement_functions");
const {
  RECOVERY_POLICY_VERSION,
  recoveryDecision,
  recoveryMediaPath,
} = require("./premium_recovery_logic");

const db = admin.firestore();

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
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
    ? chatData.participants.filter((value) => typeof value === "string" && value)
    : [];
}

async function captureDownloadedReceiverRecovery({
  uid,
  chatId,
  messageId,
  chatData,
  messageData,
}) {
  if (!messageData || messageData.receiverId !== uid) {
    return { captured: false, reason: "not-receiver" };
  }
  const type = typeof messageData.type === "string" ? messageData.type : "text";
  if (type === "text") return { captured: false, reason: "not-media" };

  const acknowledgements = messageData.downloadAcknowledgements &&
    typeof messageData.downloadAcknowledgements === "object"
    ? messageData.downloadAcknowledgements
    : {};
  if (acknowledgements[uid] == null) {
    return { captured: false, reason: "receiver-media-not-downloaded" };
  }

  const entitlement = await readPremiumEntitlement(uid);
  const timestampMs = timestampMillis(messageData.timestamp);
  const decision = recoveryDecision({
    uid,
    entitlement,
    clearCutoffMs: clearCutoffMillis(chatData, uid),
    message: { ...messageData, timestampMs },
  });
  if (!decision.eligible) {
    return { captured: false, reason: decision.reason };
  }

  const sourcePath = messageData.mediaStoragePath;
  if (typeof sourcePath !== "string" || !sourcePath) {
    throw new Error("Downloaded receiver media has no trusted storage path.");
  }
  const destinationPath = recoveryMediaPath({
    uid,
    chatId,
    messageId,
    sourcePath,
  });
  const bucket = admin.storage().bucket();
  const source = bucket.file(sourcePath);
  const destination = bucket.file(destinationPath);
  const [sourceExists] = await source.exists();
  if (!sourceExists) {
    throw new Error("Downloaded receiver media disappeared before recovery capture.");
  }
  const [destinationExists] = await destination.exists();
  if (!destinationExists) await source.copy(destination);

  const assignedAt = admin.firestore.Timestamp.now();
  const recoveryExpiresAt = admin.firestore.Timestamp.fromMillis(
    decision.recoveryExpiresAtMs,
  );
  const userRef = db.collection("premiumRecoveryUsers").doc(uid);
  const chatRef = userRef.collection("chats").doc(chatId);
  const recoveryMessageRef = chatRef.collection("messages").doc(messageId);
  const batch = db.batch();
  batch.set(recoveryMessageRef, {
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
    recoveryMediaStoragePath: destinationPath,
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
  batch.set(userRef, {
    ownerId: uid,
    updatedAt: assignedAt,
    recoveryPolicyVersion: RECOVERY_POLICY_VERSION,
  }, { merge: true });
  await batch.commit();

  return { captured: true, reason: "eligible" };
}

module.exports = { captureDownloadedReceiverRecovery };
