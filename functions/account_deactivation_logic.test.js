"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  chatPeerAvailability,
  isActiveAccountData,
  isDeactivatedValue,
} = require("./account_deactivation_logic");

test("isDeactivatedValue only treats literal true as deactivated", () => {
  assert.equal(isDeactivatedValue(true), true);
  assert.equal(isDeactivatedValue(false), false);
  assert.equal(isDeactivatedValue(undefined), false);
  assert.equal(isDeactivatedValue("true"), false);
});

test("isActiveAccountData rejects suspended and deactivated accounts", () => {
  assert.equal(isActiveAccountData({}), true);
  assert.equal(isActiveAccountData({ isSuspended: true }), false);
  assert.equal(isActiveAccountData({ isDeactivated: true }), false);
  assert.equal(
    isActiveAccountData({ isSuspended: false, isDeactivated: false }),
    true,
  );
  assert.equal(isActiveAccountData(null), false);
});

test("chatPeerAvailability distinguishes missing and deactivated peers", () => {
  assert.deepEqual(chatPeerAvailability(null), {
    unavailable: true,
    deactivated: false,
    effectivelyOnlineAllowed: false,
  });

  assert.deepEqual(chatPeerAvailability({ isDeactivated: true }), {
    unavailable: false,
    deactivated: true,
    effectivelyOnlineAllowed: false,
  });

  assert.deepEqual(chatPeerAvailability({ isDeactivated: false }), {
    unavailable: false,
    deactivated: false,
    effectivelyOnlineAllowed: true,
  });
});
