"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeDecision,
  normalizeDecisionNote,
  normalizeReportId,
  normalizeReportStatus,
  safeReportProjection,
} = require("./admin_reports_logic");

test("report id rejects path-like or empty values", () => {
  assert.equal(normalizeReportId("abc123"), "abc123");
  assert.equal(normalizeReportId(" reports/123 "), null);
  assert.equal(normalizeReportId(""), null);
});

test("status and decision values fail closed", () => {
  assert.equal(normalizeReportStatus("all"), "all");
  assert.equal(normalizeReportStatus("PENDING"), "pending");
  assert.equal(normalizeReportStatus("unknown"), null);
  assert.equal(normalizeDecision("resolved"), "resolved");
  assert.equal(normalizeDecision("dismissed"), "dismissed");
  assert.equal(normalizeDecision("pending"), "pending");
  assert.equal(normalizeDecision("delete"), null);
});

test("decision note requires bounded meaningful text", () => {
  assert.equal(normalizeDecisionNote("ok"), null);
  assert.equal(normalizeDecisionNote(" reviewed and resolved "), "reviewed and resolved");
  assert.equal(normalizeDecisionNote("x".repeat(501)), null);
});

test("safe report projection excludes arbitrary private fields", () => {
  const projected = safeReportProjection("r1", {
    reporterId: "u1",
    reportedUserId: "u2",
    reason: "spam",
    description: "details",
    status: "pending",
    exactLocation: { lat: 1, lng: 2 },
    privateChat: "secret",
    token: "secret",
  });
  assert.equal(projected.id, "r1");
  assert.equal(projected.reporterId, "u1");
  assert.equal(projected.reportedUserId, "u2");
  assert.equal(projected.reason, "spam");
  assert.equal(projected.description, "details");
  assert.equal(Object.hasOwn(projected, "exactLocation"), false);
  assert.equal(Object.hasOwn(projected, "privateChat"), false);
  assert.equal(Object.hasOwn(projected, "token"), false);
});

test("unknown legacy status is treated as pending", () => {
  assert.equal(safeReportProjection("r1", { status: "weird" }).status, "pending");
});
