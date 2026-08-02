"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { evaluateAdminAuthorization } = require("./admin_session_logic");

test("rejects unauthenticated request", () => {
  assert.deepEqual(evaluateAdminAuthorization(null, "dashboard.read"), {
    ok: false,
    code: "unauthenticated",
  });
});

test("rejects unknown role", () => {
  assert.deepEqual(
    evaluateAdminAuthorization(
      { uid: "u", token: { nearmeuAdminRole: "superuser" } },
      "dashboard.read",
    ),
    { ok: false, code: "permission-denied" },
  );
});

test("owner passes requested permission without pre-granting future permissions", () => {
  const result = evaluateAdminAuthorization(
    {
      uid: "owner",
      token: {
        nearmeuAdminRole: "owner",
        nearmeuAdminPermissions: ["dashboard.read"],
      },
    },
    "future.permission",
  );
  assert.equal(result.ok, true);
  assert.equal(result.actor.role, "owner");
});

test("admin requires explicit permission", () => {
  const denied = evaluateAdminAuthorization(
    {
      uid: "admin",
      token: {
        nearmeuAdminRole: "admin",
        nearmeuAdminPermissions: ["dashboard.read"],
      },
    },
    "premium.manage",
  );
  assert.deepEqual(denied, { ok: false, code: "permission-denied" });

  const allowed = evaluateAdminAuthorization(
    {
      uid: "admin",
      token: {
        nearmeuAdminRole: "admin",
        nearmeuAdminPermissions: ["dashboard.read"],
      },
    },
    "dashboard.read",
  );
  assert.equal(allowed.ok, true);
  assert.equal(allowed.actor.role, "admin");
});

test("non-string permissions are ignored", () => {
  const result = evaluateAdminAuthorization(
    {
      uid: "admin",
      token: {
        nearmeuAdminRole: "admin",
        nearmeuAdminPermissions: ["dashboard.read", 42, null],
      },
    },
    "dashboard.read",
  );
  assert.equal(result.ok, true);
  assert.deepEqual(result.actor.permissions, ["dashboard.read"]);
});
