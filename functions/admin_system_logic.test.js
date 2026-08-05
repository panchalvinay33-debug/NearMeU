"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { buildSystemHealth } = require("./admin_system_logic");

function ok(detail = "ok") {
  return { status: "ok", detail, authoritative: true };
}

test("system health reports ok when all authoritative checks pass", () => {
  const result = buildSystemHealth({
    firestore: ok(), auth: ok(), storage: ok(), functions: ok(),
    release: ok(), premium: ok(), recovery: ok(),
    crashlytics: { status: "unavailable", detail: "not integrated", authoritative: false },
  });
  assert.equal(result.overallStatus, "ok");
  assert.equal(result.verifiedChecks, 7);
  assert.equal(result.unavailableChecks, 1);
  assert.equal(result.checks.length, 8);
});

test("system health surfaces authoritative errors without converting unavailable telemetry to failure", () => {
  const result = buildSystemHealth({
    firestore: { status: "error", detail: "failed", authoritative: true },
    auth: ok(), storage: ok(), functions: ok(), release: ok(), premium: ok(), recovery: ok(),
    crashlytics: { status: "unavailable", detail: "not integrated", authoritative: false },
  });
  assert.equal(result.overallStatus, "error");
  assert.equal(result.unavailableChecks, 1);
});
