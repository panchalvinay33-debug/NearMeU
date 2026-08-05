"use strict";

const REPORT_DECISIONS = Object.freeze(["resolved", "dismissed", "pending"]);

function normalizeReportId(value) {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > 256 || trimmed.includes("/")) return null;
  return trimmed;
}

function normalizeReportStatus(value) {
  if (value == null || value === "all") return "all";
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  return ["pending", "resolved", "dismissed"].includes(normalized)
    ? normalized
    : null;
}

function normalizeDecision(value) {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  return REPORT_DECISIONS.includes(normalized) ? normalized : null;
}

function normalizeDecisionNote(value) {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length >= 4 && trimmed.length <= 500 ? trimmed : null;
}

function timestampMillis(value) {
  if (value == null) return null;
  if (Number.isFinite(value)) return Number(value);
  if (value instanceof Date) return value.getTime();
  if (typeof value.toMillis === "function") return value.toMillis();
  return null;
}

function safeReportProjection(id, data) {
  const safe = data && typeof data === "object" ? data : {};
  return {
    id,
    reporterId: typeof safe.reporterId === "string" ? safe.reporterId : null,
    reportedUserId: typeof safe.reportedUserId === "string" ? safe.reportedUserId : null,
    reason: typeof safe.reason === "string" ? safe.reason.slice(0, 200) : "",
    description: typeof safe.description === "string" ? safe.description.slice(0, 1000) : "",
    status: ["pending", "resolved", "dismissed"].includes(safe.status)
      ? safe.status
      : "pending",
    createdAtMillis: timestampMillis(safe.createdAt),
    reviewedAtMillis: timestampMillis(safe.reviewedAt || safe.resolvedAt),
    reviewedBy: typeof safe.reviewedBy === "string"
      ? safe.reviewedBy
      : typeof safe.resolvedBy === "string"
        ? safe.resolvedBy
        : null,
    decisionNote: safe.moderation && typeof safe.moderation === "object" &&
      typeof safe.moderation.note === "string"
      ? safe.moderation.note.slice(0, 500)
      : null,
  };
}

module.exports = {
  REPORT_DECISIONS,
  normalizeDecision,
  normalizeDecisionNote,
  normalizeReportId,
  normalizeReportStatus,
  safeReportProjection,
  timestampMillis,
};
