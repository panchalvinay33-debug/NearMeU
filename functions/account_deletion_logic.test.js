"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  RECENT_AUTH_WINDOW_SECONDS,
  accountDeletionMarker,
  authenticationAgeSeconds,
  isRecentAuthentication,
} = require("./account_deletion_logic");

const NOW_MS = 1_800_000_000_000;
const NOW_SECONDS = Math.floor(NOW_MS / 1000);

function authAt(seconds) {
  return { token: { auth_time: seconds } };
}

test("recent authentication is accepted", () => {
  const auth = authAt(NOW_SECONDS - RECENT_AUTH_WINDOW_SECONDS + 1);
  assert.equal(isRecentAuthentication(auth, NOW_MS), true);
});

test("stale authentication is rejected", () => {
  const auth = authAt(NOW_SECONDS - RECENT_AUTH_WINDOW_SECONDS - 1);
  assert.equal(isRecentAuthentication(auth, NOW_MS), false);
});

test("missing or malformed auth time is rejected", () => {
  assert.equal(isRecentAuthentication(null, NOW_MS), false);
  assert.equal(isRecentAuthentication({ token: {} }, NOW_MS), false);
  assert.equal(isRecentAuthentication(authAt("invalid"), NOW_MS), false);
});

test("small clock skew is tolerated but large future timestamps are rejected", () => {
  assert.equal(isRecentAuthentication(authAt(NOW_SECONDS + 30), NOW_MS), true);
  assert.equal(isRecentAuthentication(authAt(NOW_SECONDS + 61), NOW_MS), false);
});

test("authentication age is calculated in whole seconds", () => {
  assert.equal(authenticationAgeSeconds(authAt(NOW_SECONDS - 42), NOW_MS), 42);
});

test("account deletion markers are deterministic", () => {
  assert.equal(accountDeletionMarker(" user-1 "), "deleted:user-1");
  assert.throws(() => accountDeletionMarker(""), TypeError);
});
