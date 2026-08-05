"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  agoraUidFromFirebaseUid,
  canTransition,
  channelNameForCall,
  createCallId,
  isTerminalStatus,
  nextStatus,
  participantRole,
  pointerAvailable,
  safeDisplayName,
  validCallId,
} = require("./audio_call_r2_logic");

test("generated call IDs are valid and produce stable channel names", () => {
  const callId = createCallId();
  assert.equal(validCallId(callId), true);
  assert.equal(channelNameForCall(callId), `nm_${callId}`);
});

test("Firebase UIDs map deterministically to non-zero Agora UIDs", () => {
  const first = agoraUidFromFirebaseUid("user-a");
  const second = agoraUidFromFirebaseUid("user-a");
  assert.equal(first, second);
  assert.notEqual(first, 0);
  assert.throws(() => agoraUidFromFirebaseUid(""), /invalid-user-id/);
});

test("participant roles are exact and outsiders are denied", () => {
  const call = { callerUid: "caller", calleeUid: "callee" };
  assert.equal(participantRole(call, "caller"), "caller");
  assert.equal(participantRole(call, "callee"), "callee");
  assert.equal(participantRole(call, "other"), null);
});

test("ringing call transition contract is narrow", () => {
  assert.equal(canTransition({ status: "ringing", actorRole: "callee", action: "accept" }), true);
  assert.equal(canTransition({ status: "ringing", actorRole: "callee", action: "decline" }), true);
  assert.equal(canTransition({ status: "ringing", actorRole: "caller", action: "end" }), true);
  assert.equal(canTransition({ status: "ringing", actorRole: "caller", action: "accept" }), false);
  assert.equal(nextStatus({ status: "ringing", actorRole: "callee", action: "accept" }), "accepted");
  assert.equal(nextStatus({ status: "ringing", actorRole: "callee", action: "decline" }), "declined");
});

test("accepted calls may only be ended by a participant", () => {
  assert.equal(canTransition({ status: "accepted", actorRole: "caller", action: "end" }), true);
  assert.equal(canTransition({ status: "accepted", actorRole: "callee", action: "end" }), true);
  assert.equal(canTransition({ status: "accepted", actorRole: "callee", action: "decline" }), false);
  assert.equal(canTransition({ status: "accepted", actorRole: null, action: "end" }), false);
});

test("terminal states cannot transition again", () => {
  for (const status of ["declined", "ended", "missed", "expired"]) {
    assert.equal(isTerminalStatus(status), true);
    assert.equal(canTransition({ status, actorRole: "caller", action: "end" }), false);
  }
});

test("active pointer is reusable only after a valid expiry", () => {
  assert.equal(pointerAvailable(null, 1000), true);
  assert.equal(pointerAvailable({ expiresAtMillis: 999 }, 1000), true);
  assert.equal(pointerAvailable({ expiresAtMillis: 1001 }, 1000), false);
  assert.equal(pointerAvailable({ expiresAtMillis: 0 }, 1000), false);
  assert.equal(pointerAvailable({}, 1000), false);
});

test("display names are bounded and safe", () => {
  assert.equal(safeDisplayName("  Vinay   Panchal  "), "Vinay Panchal");
  assert.equal(safeDisplayName(""), "NearMeU user");
  assert.equal(safeDisplayName("x".repeat(50)).length, 30);
});
