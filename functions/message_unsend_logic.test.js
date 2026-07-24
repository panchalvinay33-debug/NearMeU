"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  UNSEND_WINDOW_MS,
  deterministicChatId,
  normalizeUnsendRequest,
  unsendDecision,
} = require("./message_unsend_logic");

test("normalizes a deterministic private chat unsend request", () => {
  const actorId = "sender-user";
  const otherUserId = "receiver-user";
  const result = normalizeUnsendRequest(
    {
      otherUserId,
      messageId: "message_1234567890",
    },
    actorId,
  );
  assert.equal(result.chatId, deterministicChatId(actorId, otherUserId));
  assert.equal(result.otherUserId, otherUserId);
});

test("allows the sender through the exact sixty-minute boundary", () => {
  const input = {
    actorId: "sender",
    senderId: "sender",
    receiverId: "receiver",
    otherUserId: "receiver",
    isUnsent: false,
    timestampMs: 1000,
  };
  assert.equal(
    unsendDecision({
      ...input,
      nowMs: 1000 + UNSEND_WINDOW_MS,
    }).allowed,
    true,
  );
  assert.deepEqual(
    unsendDecision({
      ...input,
      nowMs: 1001 + UNSEND_WINDOW_MS,
    }),
    {
      allowed: false,
      reason: "window-expired",
      ageMs: UNSEND_WINDOW_MS + 1,
    },
  );
});

test("rejects another user and a mismatched receiver", () => {
  const base = {
    actorId: "sender",
    senderId: "sender",
    receiverId: "receiver",
    otherUserId: "receiver",
    isUnsent: false,
    timestampMs: 1000,
    nowMs: 2000,
  };
  assert.equal(
    unsendDecision({ ...base, actorId: "intruder" }).reason,
    "not-sender",
  );
  assert.equal(
    unsendDecision({ ...base, otherUserId: "another" }).reason,
    "wrong-chat",
  );
});

test("already-unsent retries remain idempotently allowed", () => {
  assert.deepEqual(
    unsendDecision({
      actorId: "sender",
      senderId: "sender",
      receiverId: "receiver",
      otherUserId: "receiver",
      isUnsent: true,
      timestampMs: 0,
      nowMs: UNSEND_WINDOW_MS * 10,
    }),
    {
      allowed: true,
      alreadyUnsent: true,
      reason: "already-unsent",
    },
  );
});

test("invalid request identifiers are rejected", () => {
  assert.throws(
    () =>
      normalizeUnsendRequest(
        { otherUserId: "sender", messageId: "message_1234567890" },
        "sender",
      ),
    /same user/,
  );
  assert.throws(
    () =>
      normalizeUnsendRequest(
        { otherUserId: "receiver", messageId: "bad id" },
        "sender",
      ),
    /messageId/,
  );
});
