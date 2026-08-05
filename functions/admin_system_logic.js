"use strict";

function normalizeCheck(name, result) {
  const status = result && typeof result.status === "string"
    ? result.status
    : "unknown";
  return {
    name,
    status,
    detail: result && typeof result.detail === "string" ? result.detail : "",
    authoritative: result ? result.authoritative === true : false,
  };
}

function buildSystemHealth({ firestore, auth, storage, functions, release, premium, recovery, crashlytics }) {
  const checks = [
    normalizeCheck("firestore", firestore),
    normalizeCheck("auth", auth),
    normalizeCheck("storage", storage),
    normalizeCheck("functions", functions),
    normalizeCheck("release", release),
    normalizeCheck("premium", premium),
    normalizeCheck("recovery", recovery),
    normalizeCheck("crashlytics", crashlytics),
  ];
  const verified = checks.filter((item) => item.authoritative);
  const failing = verified.filter((item) => item.status === "error");
  const degraded = verified.filter((item) => item.status === "degraded");
  return {
    overallStatus: failing.length > 0 ? "error" : degraded.length > 0 ? "degraded" : "ok",
    verifiedChecks: verified.length,
    unavailableChecks: checks.length - verified.length,
    checks,
  };
}

module.exports = { buildSystemHealth };
