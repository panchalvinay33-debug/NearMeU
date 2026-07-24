"use strict";

const UNSEND_WINDOW_MS = 60 * 60 * 1000;
const MESSAGE_ID_PATTERN = /^[A-Za-z0-9_-]{10,128}$/;

function requiredString(value, fieldName, maximumLength = 256) {
  if (typeof value !== "string") {
    throw new TypeError(`${fieldName} is required.`);
  }
  const normalized = value.trim();
  if (!normalized || normalized.length > maximumLength) {
    throw new TypeError(`${fieldName} is invalid.`);
  }
  return normalized;
}

function deterministicChatId(firstId, secondId) {
  return [firstId, secondId].sort().join("_");
}

function normalizeUnsendRequest(data, actorId) {
  const payload = data && typeof data === "object" ? data : {};
  const otherUserId = requiredString(payload.otherUserId, "otherUserId", 128);
  if (otherUserId === actorId) {
    throw new TypeError("A private message cannot target the same user.");
  }
  const messageId = requiredString(payload.messageId, "messageId", 128);
  if (!MESSAGE_ID_PATTERN.test(messageId)) {
    throw new TypeError("messageId is invalid.");
  }
  return {
    otherUserId,
    messageId,
    chatId: deterministicChatId(actorId, otherUserId),
  };
}

function unsendDecision({
  actorId,
  senderId,
  receiverId,
  otherUserId,
  isUnsent,
  timestampMs,
  nowMs,
}) {
  if (actorId !== senderId) {
    return { allowed: false, reason: "not-sender" };
  }
  if (receiverId !== otherUserId) {
    return { allowed: false, reason: "wrong-chat" };
  }
  if (isUnsent === true) {
    return { allowed: true, alreadyUnsent: true, reason: "already-unsent" };
  }
  if (!Number.isFinite(timestampMs) || !Number.isFinite(nowMs)) {
    return { allowed: false, reason: "invalid-timestamp" };
  }
  const ageMs = Math.max(0, Math.trunc(nowMs) - Math.trunc(timestampMs));
  if (ageMs > UNSEND_WINDOW_MS) {
    return { allowed: false, reason: "window-expired", ageMs };
  }
  return { allowed: true, alreadyUnsent: false, reason: "allowed", ageMs };
}

module.exports = {
  UNSEND_WINDOW_MS,
  deterministicChatId,
  normalizeUnsendRequest,
  unsendDecision,
};
