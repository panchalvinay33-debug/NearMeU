"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  RETENTION_DAYS,
  RETENTION_MS,
  RETENTION_POLICY_VERSION,
  isExpiredAt,
  privateMediaPathAllowed,
  retentionExpiryMillis,
} = require("./message_retention_logic");

test("private messages expire exactly seven days after their timestamp", () => {
  const createdAt = Date.UTC(2026, 6, 24, 12, 0, 0);
  assert.equal(RETENTION_DAYS, 7);
  assert.equal(RETENTION_POLICY_VERSION, 1);
  assert.equal(
    retentionExpiryMillis(createdAt),
    createdAt + RETENTION_MS,
  );
});

test("expiry comparison includes the exact expiry instant", () => {
  const expiresAt = 5000;
  assert.equal(isExpiredAt({ expiresAtMs: expiresAt, nowMs: 4999 }), false);
  assert.equal(isExpiredAt({ expiresAtMs: expiresAt, nowMs: 5000 }), true);
  assert.equal(isExpiredAt({ expiresAtMs: expiresAt, nowMs: 5001 }), true);
});

test("media deletion is restricted to the exact private chat message folder", () => {
  const allowed = "privateChatMedia/chat-a/message-b/photo.jpg";
  assert.equal(
    privateMediaPathAllowed({
      path: allowed,
      chatId: "chat-a",
      messageId: "message-b",
    }),
    true,
  );
  assert.equal(
    privateMediaPathAllowed({
      path: "profilePhotos/user/photo.jpg",
      chatId: "chat-a",
      messageId: "message-b",
    }),
    false,
  );
  assert.equal(
    privateMediaPathAllowed({
      path: "privateChatMedia/chat-a/another-message/photo.jpg",
      chatId: "chat-a",
      messageId: "message-b",
    }),
    false,
  );
});

test("invalid millisecond values are rejected", () => {
  assert.throws(() => retentionExpiryMillis(Number.NaN), TypeError);
  assert.throws(
    () => isExpiredAt({ expiresAtMs: -1, nowMs: 0 }),
    TypeError,
  );
});
