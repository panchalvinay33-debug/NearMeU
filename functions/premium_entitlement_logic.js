"use strict";

const PREMIUM_GRANT_SOURCES = Object.freeze(["googlePlay", "admin"]);

function timestampMillis(value) {
  if (value == null) return null;
  if (Number.isFinite(value)) return Number(value);
  if (value instanceof Date) return value.getTime();
  if (typeof value.toMillis === "function") return value.toMillis();
  return null;
}

function activeGrant(grant, nowMs) {
  if (!grant || typeof grant !== "object" || grant.active !== true) {
    return false;
  }
  const expiresAtMs = timestampMillis(grant.expiresAt);
  return expiresAtMs == null || expiresAtMs > nowMs;
}

function evaluatePremiumEntitlement(data, nowMs = Date.now()) {
  const safeData = data && typeof data === "object" ? data : {};
  const grants = safeData.grants && typeof safeData.grants === "object"
    ? safeData.grants
    : {};
  const activeSources = [];
  const expiries = [];
  let hasNonExpiringGrant = false;

  for (const source of PREMIUM_GRANT_SOURCES) {
    const grant = grants[source];
    if (!activeGrant(grant, nowMs)) continue;
    activeSources.push(source);
    const expiresAtMs = timestampMillis(grant.expiresAt);
    if (expiresAtMs == null) {
      hasNonExpiringGrant = true;
    } else {
      expiries.push(expiresAtMs);
    }
  }

  const isPremium = activeSources.length > 0;
  const expiresAtMillis = !isPremium || hasNonExpiringGrant
    ? null
    : Math.max(...expiries);

  return {
    schemaVersion: 1,
    plan: isPremium ? "premium" : "free",
    isPremium,
    activeSources,
    expiresAtMillis,
  };
}

module.exports = {
  PREMIUM_GRANT_SOURCES,
  activeGrant,
  evaluatePremiumEntitlement,
  timestampMillis,
};
