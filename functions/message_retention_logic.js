"use strict";

const RETENTION_DAYS = 7;
const RETENTION_MS = RETENTION_DAYS * 24 * 60 * 60 * 1000;
const RETENTION_POLICY_VERSION = 1;

function finiteMillis(value, fieldName) {
  if (!Number.isFinite(value) || value < 0) {
    throw new TypeError(`${fieldName} must be a positive millisecond value.`);
  }
  return Math.trunc(value);
}

function retentionExpiryMillis(messageTimestampMs) {
  return finiteMillis(messageTimestampMs, "messageTimestampMs") + RETENTION_MS;
}

function isExpiredAt({ expiresAtMs, nowMs }) {
  return (
    finiteMillis(expiresAtMs, "expiresAtMs") <=
    finiteMillis(nowMs, "nowMs")
  );
}

function privateMediaPathAllowed({ path, chatId, messageId }) {
  if (typeof path !== "string" || !path) return false;
  if (typeof chatId !== "string" || !chatId) return false;
  if (typeof messageId !== "string" || !messageId) return false;
  return path.startsWith(`privateChatMedia/${chatId}/${messageId}/`);
}

module.exports = {
  RETENTION_DAYS,
  RETENTION_MS,
  RETENTION_POLICY_VERSION,
  isExpiredAt,
  privateMediaPathAllowed,
  retentionExpiryMillis,
};
