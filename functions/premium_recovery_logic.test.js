"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  recoveryDecision,
  recoveryExpiryMillis,
  recoveryMediaPath,
  shouldPurgeRecovery,
} = require("./premium_recovery_logic");

const premium = { isPremium: true };
const free = { isPremium: false };

test("calendar six-month expiry clips end-of-month safely", () => {
  const source = Date.UTC(2026, 7, 31, 12, 30, 0, 0);
  assert.equal(
    recoveryExpiryMillis(source),
    Date.UTC(2027, 1, 28, 12, 30, 0, 0),
  );
});

test("active Premium user receives eligible text recovery retention", () => {
  const timestampMs = Date.UTC(2026, 7, 1, 10, 0, 0, 0);
  const result = recoveryDecision({
    uid: "u1",
    entitlement: premium,
    message: { type: "text", timestampMs, deletedFor: [] },
  });
  assert.equal(result.eligible, true);
  assert.equal(result.reason, "eligible");
  assert.equal(result.recoveryExpiresAtMs, Date.UTC(2027, 1, 1, 10, 0, 0, 0));
});

test("Free user does not receive a new recovery assignment", () => {
  const result = recoveryDecision({
    uid: "u1",
    entitlement: free,
    message: { type: "text", timestampMs: 1_000, deletedFor: [] },
  });
  assert.deepEqual(result, { eligible: false, reason: "not-premium" });
});

test("sent media is eligible for Premium sender without receiver download", () => {
  const result = recoveryDecision({
    uid: "sender",
    entitlement: premium,
    message: {
      senderId: "sender",
      receiverId: "receiver",
      type: "image",
      timestampMs: 2_001,
      deletedFor: [],
      downloadAcknowledgements: { sender: 1 },
    },
  });
  assert.equal(result.eligible, true);
});

test("received media waits until Premium receiver downloaded it", () => {
  const result = recoveryDecision({
    uid: "receiver",
    entitlement: premium,
    message: {
      senderId: "sender",
      receiverId: "receiver",
      type: "video",
      timestampMs: 2_001,
      deletedFor: [],
      downloadAcknowledgements: { sender: 1 },
    },
  });
  assert.deepEqual(result, {
    eligible: false,
    reason: "receiver-media-not-downloaded",
  });
});

test("downloaded received media becomes recovery eligible", () => {
  const result = recoveryDecision({
    uid: "receiver",
    entitlement: premium,
    message: {
      senderId: "sender",
      receiverId: "receiver",
      type: "voice",
      timestampMs: 2_001,
      deletedFor: [],
      downloadAcknowledgements: { sender: 1, receiver: 2 },
    },
  });
  assert.equal(result.eligible, true);
});

test("Clear Chat cutoff prevents resurrection", () => {
  const result = recoveryDecision({
    uid: "u1",
    entitlement: premium,
    clearCutoffMs: 2_000,
    message: { type: "text", timestampMs: 2_000, deletedFor: [] },
  });
  assert.deepEqual(result, { eligible: false, reason: "cleared" });
});

test("Delete for Me prevents that user's recovery copy", () => {
  const result = recoveryDecision({
    uid: "u1",
    entitlement: premium,
    message: { type: "image", timestampMs: 2_001, deletedFor: ["u1"] },
  });
  assert.deepEqual(result, { eligible: false, reason: "deleted-for-user" });
});

test("unsent message is never recovery eligible", () => {
  const result = recoveryDecision({
    uid: "u1",
    entitlement: premium,
    message: { type: "voice", timestampMs: 2_001, isUnsent: true },
  });
  assert.deepEqual(result, { eligible: false, reason: "unsent" });
});

test("already-assigned recovery expires by recorded expiry, not current entitlement", () => {
  assert.equal(shouldPurgeRecovery({ recoveryExpiresAtMs: 5_000, nowMs: 4_999 }), false);
  assert.equal(shouldPurgeRecovery({ recoveryExpiresAtMs: 5_000, nowMs: 5_000 }), true);
});

test("recovery media lives in a separate per-user namespace", () => {
  assert.equal(
    recoveryMediaPath({
      uid: "u1",
      chatId: "c1",
      messageId: "m1",
      sourcePath: "privateChatMedia/sender/c1/m1/photo.jpg",
    }),
    "premiumRecoveryMedia/u1/c1/m1/photo.jpg",
  );
});
