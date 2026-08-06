"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { normalizeAuditLimit, projectAuditDetails, projectAuditEvent } = require("./admin_audit_logic");

test("audit limit is bounded", () => {
  assert.equal(normalizeAuditLimit(undefined), 50);
  assert.equal(normalizeAuditLimit(0), 1);
  assert.equal(normalizeAuditLimit(500), 100);
  assert.equal(normalizeAuditLimit(25), 25);
});

test("audit details expose only approved operational scalars", () => {
  const result = projectAuditDetails({
    status: "resolved",
    count: 7,
    active: true,
    email: "private@example.com",
    targetUid: "secret-target",
    note: "private moderation note",
    messageText: "private chat",
    exactLocation: "1,2",
    token: "secret",
  });
  assert.deepEqual(result, { status: "resolved", active: true, count: 7 });
});

test("audit event preserves operator accountability without raw details", () => {
  const event = projectAuditEvent("abc", {
    actorUid: "owner-uid",
    actorRole: "owner",
    action: "system.health.read",
    createdAtIso: "2026-08-06T00:00:00.000Z",
    details: { overallStatus: "ok", secret: "nope" },
  });
  assert.equal(event.actorUid, "owner-uid");
  assert.equal(event.actorRole, "owner");
  assert.equal(event.action, "system.health.read");
  assert.deepEqual(event.summary, { overallStatus: "ok" });
  assert.equal(Object.hasOwn(event, "details"), false);
});