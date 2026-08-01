"use strict";

const RECOVERY_POLICY_VERSION = 1;
const RECOVERY_MONTHS = 6;
const ALLOWED_MESSAGE_TYPES = new Set(["text", "image", "video", "voice"]);

function finiteMillis(value, fieldName) {
  if (!Number.isFinite(value) || value < 0) {
    throw new TypeError(`${fieldName} must be a positive millisecond value.`);
  }
  return Math.trunc(value);
}

function recoveryExpiryMillis(sourceTimestampMs) {
  const sourceMs = finiteMillis(sourceTimestampMs, "sourceTimestampMs");
  const source = new Date(sourceMs);
  const year = source.getUTCFullYear();
  const month = source.getUTCMonth();
  const day = source.getUTCDate();
  const hour = source.getUTCHours();
  const minute = source.getUTCMinutes();
  const second = source.getUTCSeconds();
  const millisecond = source.getUTCMilliseconds();

  const firstOfTarget = new Date(Date.UTC(
    year,
    month + RECOVERY_MONTHS,
    1,
    hour,
    minute,
    second,
    millisecond,
  ));
  const lastDayOfTargetMonth = new Date(Date.UTC(
    firstOfTarget.getUTCFullYear(),
    firstOfTarget.getUTCMonth() + 1,
    0,
  )).getUTCDate();
  firstOfTarget.setUTCDate(Math.min(day, lastDayOfTargetMonth));
  return firstOfTarget.getTime();
}

function normalizedDeletedFor(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.filter((uid) => typeof uid === "string" && uid))];
}

function hasDownloadAcknowledgement(message, uid) {
  const acknowledgements =
    message && message.downloadAcknowledgements &&
    typeof message.downloadAcknowledgements === "object"
      ? message.downloadAcknowledgements
      : {};
  return acknowledgements[uid] != null;
}

function recoveryDecision({ message, uid, entitlement, clearCutoffMs = null }) {
  if (!message || typeof message !== "object") {
    return { eligible: false, reason: "invalid-message" };
  }
  if (typeof uid !== "string" || !uid) {
    return { eligible: false, reason: "invalid-user" };
  }
  if (!entitlement || entitlement.isPremium !== true) {
    return { eligible: false, reason: "not-premium" };
  }
  if (message.isUnsent === true) {
    return { eligible: false, reason: "unsent" };
  }
  const type = typeof message.type === "string" ? message.type : "text";
  if (!ALLOWED_MESSAGE_TYPES.has(type)) {
    return { eligible: false, reason: "unsupported-type" };
  }
  if (normalizedDeletedFor(message.deletedFor).includes(uid)) {
    return { eligible: false, reason: "deleted-for-user" };
  }
  if (
    type !== "text" &&
    uid === message.receiverId &&
    !hasDownloadAcknowledgement(message, uid)
  ) {
    return { eligible: false, reason: "receiver-media-not-downloaded" };
  }

  const timestampMs = Number.isFinite(message.timestampMs)
    ? Math.trunc(message.timestampMs)
    : null;
  if (timestampMs === null || timestampMs < 0) {
    return { eligible: false, reason: "missing-timestamp" };
  }
  if (Number.isFinite(clearCutoffMs) && timestampMs <= Math.trunc(clearCutoffMs)) {
    return { eligible: false, reason: "cleared" };
  }

  return {
    eligible: true,
    reason: "eligible",
    recoveryExpiresAtMs: recoveryExpiryMillis(timestampMs),
  };
}

function shouldPurgeRecovery({ recoveryExpiresAtMs, nowMs }) {
  return (
    finiteMillis(recoveryExpiresAtMs, "recoveryExpiresAtMs") <=
    finiteMillis(nowMs, "nowMs")
  );
}

function recoveryMediaPath({ uid, chatId, messageId, sourcePath }) {
  if (typeof uid !== "string" || !uid) throw new TypeError("uid is required.");
  if (typeof chatId !== "string" || !chatId) throw new TypeError("chatId is required.");
  if (typeof messageId !== "string" || !messageId) {
    throw new TypeError("messageId is required.");
  }
  if (typeof sourcePath !== "string" || !sourcePath) {
    throw new TypeError("sourcePath is required.");
  }
  const fileName = sourcePath.split("/").filter(Boolean).pop();
  if (!fileName) throw new TypeError("sourcePath must contain a file name.");
  return `premiumRecoveryMedia/${uid}/${chatId}/${messageId}/${fileName}`;
}

module.exports = {
  ALLOWED_MESSAGE_TYPES,
  RECOVERY_MONTHS,
  RECOVERY_POLICY_VERSION,
  hasDownloadAcknowledgement,
  recoveryDecision,
  recoveryExpiryMillis,
  recoveryMediaPath,
  shouldPurgeRecovery,
};
