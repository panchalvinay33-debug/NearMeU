"use strict";

function chatDocumentKey(document) {
  if (!document || typeof document !== "object") return null;
  if (
    document.ref &&
    typeof document.ref === "object" &&
    typeof document.ref.path === "string" &&
    document.ref.path
  ) {
    return document.ref.path;
  }
  if (typeof document.path === "string" && document.path) {
    return document.path;
  }
  if (typeof document.id === "string" && document.id) {
    return document.id;
  }
  return null;
}

function shouldScanLegacyChats(normalCount, maximumPreviewCount) {
  if (!Number.isInteger(normalCount) || normalCount < 0) {
    throw new TypeError("normalCount must be a non-negative integer");
  }
  if (!Number.isInteger(maximumPreviewCount) || maximumPreviewCount <= 0) {
    throw new TypeError("maximumPreviewCount must be a positive integer");
  }
  return normalCount < maximumPreviewCount;
}

function shouldHidePreviewThroughClear(messageTimeMillis, clearedAtMillis) {
  if (!Number.isFinite(clearedAtMillis)) return false;
  if (!Number.isFinite(messageTimeMillis)) return true;
  return messageTimeMillis <= clearedAtMillis;
}

function isMessageVisibleForPreview({
  deletedFor,
  uid,
  messageTimeMillis,
  clearedAtMillis,
}) {
  if (Array.isArray(deletedFor) && deletedFor.includes(uid)) return false;
  return !shouldHidePreviewThroughClear(messageTimeMillis, clearedAtMillis);
}

function firstVisiblePreviewMessage(messages, uid, clearedAtMillis) {
  if (!Array.isArray(messages)) {
    throw new TypeError("messages must be an array");
  }
  for (const message of messages) {
    if (!message || typeof message !== "object") continue;
    if (
      isMessageVisibleForPreview({
        deletedFor: message.deletedFor,
        uid,
        messageTimeMillis: message.messageTimeMillis,
        clearedAtMillis,
      })
    ) {
      return message;
    }
  }
  return null;
}

function mergeChatDocuments({
  normalDocuments = [],
  legacyDocuments = [],
  maximumDocuments,
}) {
  if (!Array.isArray(normalDocuments) || !Array.isArray(legacyDocuments)) {
    throw new TypeError("chat document inputs must be arrays");
  }
  if (!Number.isInteger(maximumDocuments) || maximumDocuments <= 0) {
    throw new TypeError("maximumDocuments must be a positive integer");
  }

  const merged = new Map();
  for (const document of [...normalDocuments, ...legacyDocuments]) {
    const key = chatDocumentKey(document);
    if (!key || merged.has(key)) continue;
    merged.set(key, document);
    if (merged.size >= maximumDocuments) break;
  }
  return [...merged.values()];
}

module.exports = {
  chatDocumentKey,
  firstVisiblePreviewMessage,
  isMessageVisibleForPreview,
  mergeChatDocuments,
  shouldHidePreviewThroughClear,
  shouldScanLegacyChats,
};
