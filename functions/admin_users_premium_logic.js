"use strict";

function normalizeLookupQuery(value) {
  if (typeof value !== "string") return null;
  const query = value.trim();
  if (!query || query.length > 320) return null;
  return query;
}

function normalizeUid(value) {
  if (typeof value !== "string") return null;
  const uid = value.trim();
  if (!uid || uid.length > 128 || /\s/.test(uid)) return null;
  return uid;
}

function normalizeReason(value, { required = false } = {}) {
  if (value == null && !required) return "";
  if (typeof value !== "string") return null;
  const reason = value.trim();
  if (required && !reason) return null;
  if (reason.length > 300) return null;
  return reason;
}

function normalizePremiumDays(value) {
  if (!Number.isInteger(value)) return null;
  if (![7, 30, 90, 365].includes(value)) return null;
  return value;
}

function premiumExpiryMillis(days, nowMs = Date.now()) {
  return nowMs + days * 24 * 60 * 60 * 1000;
}

function safeTimestampMillis(value) {
  if (!value || typeof value.toMillis !== "function") return null;
  return value.toMillis();
}

module.exports = {
  normalizeLookupQuery,
  normalizeUid,
  normalizeReason,
  normalizePremiumDays,
  premiumExpiryMillis,
  safeTimestampMillis,
};
