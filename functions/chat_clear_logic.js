"use strict";

function requiredString(value, fieldName, maximumLength = 128) {
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

function normalizeClearChatRequest(data, actorId) {
  const payload = data && typeof data === "object" ? data : {};
  const otherUserId = requiredString(payload.otherUserId, "otherUserId");
  if (otherUserId === actorId) {
    throw new TypeError("A private chat requires two different users.");
  }
  return {
    otherUserId,
    chatId: deterministicChatId(actorId, otherUserId),
  };
}

function isExactPrivateChatParticipants(participants, actorId, otherUserId) {
  if (!Array.isArray(participants) || participants.length !== 2) return false;
  const normalized = participants.filter((value) => typeof value === "string").sort();
  const expected = [actorId, otherUserId].sort();
  return normalized.length === 2 &&
    normalized[0] === expected[0] &&
    normalized[1] === expected[1];
}

function shouldHideMessageThroughClear(messageTimestampMs, clearedAtMs) {
  if (!Number.isFinite(messageTimestampMs) || !Number.isFinite(clearedAtMs)) {
    return false;
  }
  return Math.trunc(messageTimestampMs) <= Math.trunc(clearedAtMs);
}

module.exports = {
  deterministicChatId,
  normalizeClearChatRequest,
  isExactPrivateChatParticipants,
  shouldHideMessageThroughClear,
};
