"use strict";

const MESSAGE_WINDOW_MS = 60 * 1000;
const MAX_MESSAGES_PER_WINDOW = 30;
const MIN_MESSAGE_INTERVAL_MS = 1000;
const REPORT_WINDOW_MS = 24 * 60 * 60 * 1000;
const MAX_REPORTS_PER_WINDOW = 5;
const REPORT_REPEAT_COOLDOWN_MS = 7 * 24 * 60 * 60 * 1000;
const MAX_MESSAGE_LENGTH = 1000;
const MAX_DESCRIPTION_LENGTH = 500;
const MAX_USER_ID_LENGTH = 128;
const ALLOWED_REPORT_REASONS = new Set([
  "Spam",
  "Fake Profile",
  "Harassment",
  "Hate Speech",
  "Scam/Fraud",
  "Inappropriate Content",
  "Other",
]);

function normalizedUserId(value, fieldName = "userId") {
  const userId = typeof value === "string" ? value.trim() : "";
  if (!userId || userId.length > MAX_USER_ID_LENGTH) {
    throw new TypeError(`${fieldName} is invalid.`);
  }
  return userId;
}

function normalizedMessage(value) {
  const message = typeof value === "string" ? value.trim() : "";
  if (!message) throw new TypeError("Message cannot be empty.");
  if (message.length > MAX_MESSAGE_LENGTH) {
    throw new TypeError(
      `Message cannot be longer than ${MAX_MESSAGE_LENGTH} characters.`,
    );
  }
  return message;
}

function normalizedReply(value, participants) {
  if (value == null) return null;
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new TypeError("Reply metadata is invalid.");
  }

  const messageId = typeof value.messageId === "string"
    ? value.messageId.trim()
    : "";
  const text = typeof value.text === "string" ? value.text.trim() : "";
  const senderId = normalizedUserId(value.senderId, "reply senderId");

  if (!messageId || messageId.length > 256) {
    throw new TypeError("Reply messageId is invalid.");
  }
  if (text.length > MAX_MESSAGE_LENGTH) {
    throw new TypeError("Reply preview is too long.");
  }
  if (!participants.includes(senderId)) {
    throw new TypeError("Reply sender is not a chat participant.");
  }

  return { messageId, text, senderId };
}

function normalizedReport(reasonValue, descriptionValue) {
  const reason = typeof reasonValue === "string" ? reasonValue.trim() : "";
  if (!ALLOWED_REPORT_REASONS.has(reason)) {
    throw new TypeError("Report reason is invalid.");
  }

  const description = typeof descriptionValue === "string"
    ? descriptionValue.trim()
    : "";
  if (description.length > MAX_DESCRIPTION_LENGTH) {
    throw new TypeError(
      `Report description cannot exceed ${MAX_DESCRIPTION_LENGTH} characters.`,
    );
  }
  if (reason === "Other" && !description) {
    throw new TypeError("Please describe the problem.");
  }

  return { reason, description };
}

function consumeFixedWindow({
  nowMs,
  windowStartedAtMs,
  count,
  windowMs,
  maxCount,
}) {
  if (!Number.isFinite(nowMs)) throw new TypeError("nowMs is required.");
  const previousStart = Number.isFinite(windowStartedAtMs)
    ? windowStartedAtMs
    : null;
  const previousCount = Number.isInteger(count) && count >= 0 ? count : 0;
  const expired = previousStart == null || nowMs - previousStart >= windowMs;
  const startMs = expired ? nowMs : previousStart;
  const currentCount = expired ? 0 : previousCount;

  if (currentCount >= maxCount) {
    return {
      allowed: false,
      count: currentCount,
      windowStartedAtMs: startMs,
      retryAfterMs: Math.max(0, startMs + windowMs - nowMs),
    };
  }

  return {
    allowed: true,
    count: currentCount + 1,
    windowStartedAtMs: startMs,
    retryAfterMs: 0,
  };
}

function messageRateDecision({ nowMs, lastMessageAtMs, windowStartedAtMs, count }) {
  if (
    Number.isFinite(lastMessageAtMs) &&
    nowMs - lastMessageAtMs < MIN_MESSAGE_INTERVAL_MS
  ) {
    return {
      allowed: false,
      reason: "minimum_interval",
      retryAfterMs: MIN_MESSAGE_INTERVAL_MS - (nowMs - lastMessageAtMs),
      count: Number.isInteger(count) ? count : 0,
      windowStartedAtMs: Number.isFinite(windowStartedAtMs)
        ? windowStartedAtMs
        : nowMs,
    };
  }

  const window = consumeFixedWindow({
    nowMs,
    windowStartedAtMs,
    count,
    windowMs: MESSAGE_WINDOW_MS,
    maxCount: MAX_MESSAGES_PER_WINDOW,
  });
  return {
    ...window,
    reason: window.allowed ? null : "window_limit",
  };
}

function reportRateDecision({ nowMs, windowStartedAtMs, count }) {
  return consumeFixedWindow({
    nowMs,
    windowStartedAtMs,
    count,
    windowMs: REPORT_WINDOW_MS,
    maxCount: MAX_REPORTS_PER_WINDOW,
  });
}

function isWithinReportCooldown(nowMs, lastReportAtMs) {
  return Number.isFinite(lastReportAtMs) &&
    nowMs - lastReportAtMs < REPORT_REPEAT_COOLDOWN_MS;
}

module.exports = {
  ALLOWED_REPORT_REASONS,
  MAX_DESCRIPTION_LENGTH,
  MAX_MESSAGES_PER_WINDOW,
  MAX_REPORTS_PER_WINDOW,
  MESSAGE_WINDOW_MS,
  MIN_MESSAGE_INTERVAL_MS,
  REPORT_REPEAT_COOLDOWN_MS,
  REPORT_WINDOW_MS,
  consumeFixedWindow,
  isWithinReportCooldown,
  messageRateDecision,
  normalizedMessage,
  normalizedReply,
  normalizedReport,
  normalizedUserId,
  reportRateDecision,
};
