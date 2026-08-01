"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  ACCOUNT_STATE_ACTIVE,
  ACCOUNT_STATE_CLOSED,
  accountState,
  closedPublicProfile,
  identityEmailKey,
  normalizeVerifiedEmail,
} = require("./account_lifecycle_logic");

test("normalizes verified email deterministically", () => {
  assert.equal(normalizeVerifiedEmail("  User@Example.COM "), "user@example.com");
  assert.equal(normalizeVerifiedEmail(null), "");
  assert.equal(identityEmailKey("User@example.com"), identityEmailKey(" user@EXAMPLE.com "));
});

test("legacy account state defaults active", () => {
  assert.equal(accountState({}), ACCOUNT_STATE_ACTIVE);
  assert.equal(accountState({ accountState: ACCOUNT_STATE_ACTIVE }), ACCOUNT_STATE_ACTIVE);
  assert.equal(accountState({ accountState: ACCOUNT_STATE_CLOSED }), ACCOUNT_STATE_CLOSED);
});

test("closed public profile removes discoverability and public profile data", () => {
  const marker = { seconds: 123 };
  const result = closedPublicProfile(
    "uid-1",
    {
      nickname: "Alice",
      age: 29,
      isAdmin: true,
      isSuspended: false,
      createdAt: { seconds: 10 },
      privacyVersion: 1,
      approxLatitude: 22.1,
      locationCell: "abc",
      photoUrl: "https://example.test/a.jpg",
    },
    marker,
  );

  assert.equal(result.uid, "uid-1");
  assert.equal(result.nickname, "Account unavailable");
  assert.equal(result.age, 29);
  assert.equal(result.isAdmin, true);
  assert.equal(result.accountState, ACCOUNT_STATE_CLOSED);
  assert.equal(result.photoUrl, null);
  assert.equal(result.locationCell, null);
  assert.deepEqual(result.discoveryCells, []);
  assert.equal(result.closedAt, marker);
});
