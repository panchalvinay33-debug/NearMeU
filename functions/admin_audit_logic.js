"use strict";

const SAFE_DETAIL_KEYS = new Set([
  "status",
  "decision",
  "suspended",
  "active",
  "days",
  "source",
  "windowHours",
  "sampledMessages",
  "overallStatus",
  "verifiedChecks",
  "unavailableChecks",
  "generatedAtMillis",
  "count",
  "result",
]);

function safeScalar(value) {
  if (typeof value === "boolean" || typeof value === "number") return value;
  if (typeof value === "string") return value.slice(0, 80);
  return null;
}

function projectAuditDetails(details) {
  if (!details || typeof details !== "object" || Array.isArray(details)) return {};
  const projected = {};
  for (const key of SAFE_DETAIL_KEYS) {
    if (!Object.prototype.hasOwnProperty.call(details, key)) continue;
    const value = safeScalar(details[key]);
    if (value !== null) projected[key] = value;
  }
  return projected;
}

function timestampMillis(data) {
  const value = data && data.createdAt;
  if (value && typeof value.toMillis === "function") return value.toMillis();
  const iso = data && typeof data.createdAtIso === "string" ? data.createdAtIso : "";
  const parsed = Date.parse(iso);
  return Number.isFinite(parsed) ? parsed : 0;
}

function projectAuditEvent(id, data) {
  const source = data && typeof data === "object" ? data : {};
  return {
    id: String(id || ""),
    actorUid: typeof source.actorUid === "string" ? source.actorUid : "unknown",
    actorRole: typeof source.actorRole === "string" ? source.actorRole : "unknown",
    action: typeof source.action === "string" ? source.action : "unknown",
    createdAtMillis: timestampMillis(source),
    summary: projectAuditDetails(source.details),
  };
}

function normalizeAuditLimit(value) {
  if (!Number.isInteger(value)) return 50;
  return Math.max(1, Math.min(100, value));
}

module.exports = {
  normalizeAuditLimit,
  projectAuditDetails,
  projectAuditEvent,
};