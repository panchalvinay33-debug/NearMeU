"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  ACCOUNT_STATE_ACTIVE,
  ACCOUNT_STATE_CLOSED,
  accountState,
  closedLifecycleRecord,
  identityEmailKey,
  normalizeVerifiedEmail,
} = require("./account_lifecycle_logic");

test("normalizes verified email deterministically", () => {
  assert.equal(normalizeVerifiedEmail("  User@Example.COM "), "user@example.com");
  assert.equal(normalizeVerifiedEmail(null), "");
  assert.equal(
    identityEmailKey("User@example.com"),
    identityEmailKey(" user@EXAMPLE.com "),
  );
});

test("legacy lifecycle state defaults active", () => {
  assert.equal(accountState({}), ACCOUNT_STATE_ACTIVE);
  assert.equal(accountState({ accountState: ACCOUNT_STATE_ACTIVE }), ACCOUNT_STATE_ACTIVE);
  assert.equal(accountState({ accountState: ACCOUNT_STATE_CLOSED }), ACCOUNT_STATE_CLOSED);
});

test("closed lifecycle record preserves internal continuity flags", () => {
  const marker = { seconds: 123 };
  const createdAt = { seconds: 10 };
  const result = closedLifecycleRecord(
    "uid-1",
    {
      createdAt,
      isAdmin: false,
      isSuspended: false,
    },
    marker,
  );

  assert.equal(result.uid, "uid-1");
  assert.equal(result.accountState, ACCOUNT_STATE_CLOSED);
  assert.equal(result.closedAt, marker);
  assert.equal(result.preservedCreatedAt, createdAt);
  assert.equal(result.preservedIsAdmin, false);
  assert.equal(result.preservedIsSuspended, false);
});
