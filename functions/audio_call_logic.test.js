"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  agoraUidFromFirebaseUid,
  channelNameForCall,
  createCallId,
  isTerminalCallStatus,
  participantRole,
  pointerAvailable,
  safeDisplayName,
  validCallId,
} = require("./audio_call_logic");

test("call ids are opaque URL-safe identifiers", () => {
  const first = createCallId();
  const second = createCallId();
  assert.equal(validCallId(first), true);
  assert.equal(validCallId(second), true);
  assert.notEqual(first, second);
  assert.equal(channelNameForCall(first), `nm_${first}`);
});

test("invalid call ids are rejected", () => {
  for (const value of ["", "abc", "contains/slash", "contains space", null]) {
    assert.equal(validCallId(value), false);
  }
});

test("firebase uid maps deterministically to non-zero Agora uid", () => {
  const first = agoraUidFromFirebaseUid("user-a");
  assert.equal(first, agoraUidFromFirebaseUid("user-a"));
  assert.notEqual(first, 0);
  assert.notEqual(first, agoraUidFromFirebaseUid("user-b"));
});

test("participant role accepts only the two call participants", () => {
  const call = { callerUid: "a", calleeUid: "b" };
  assert.equal(participantRole(call, "a"), "caller");
  assert.equal(participantRole(call, "b"), "callee");
  assert.equal(participantRole(call, "c"), null);
});

test("terminal statuses are explicit", () => {
  assert.equal(isTerminalCallStatus("ended"), true);
  assert.equal(isTerminalCallStatus("declined"), true);
  assert.equal(isTerminalCallStatus("missed"), true);
  assert.equal(isTerminalCallStatus("expired"), true);
  assert.equal(isTerminalCallStatus("ringing"), false);
  assert.equal(isTerminalCallStatus("accepted"), false);
});

test("active call pointer expires closed rather than locking forever", () => {
  assert.equal(pointerAvailable(null, 1000), true);
  assert.equal(pointerAvailable({ expiresAtMillis: 999 }, 1000), true);
  assert.equal(pointerAvailable({ expiresAtMillis: 1001 }, 1000), false);
});

test("display names are privacy-safe and bounded", () => {
  assert.equal(safeDisplayName("   "), "NearMeU user");
  assert.equal(safeDisplayName(" A   User "), "A User");
  assert.equal(safeDisplayName("x".repeat(100)).length, 30);
});
