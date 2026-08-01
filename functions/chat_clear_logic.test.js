"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  deterministicChatId,
  normalizeClearChatRequest,
  isExactPrivateChatParticipants,
  shouldHideMessageThroughClear,
} = require("./chat_clear_logic");

test("normalizes a deterministic private-chat clear request", () => {
  const result = normalizeClearChatRequest(
    { otherUserId: "receiver-user" },
    "sender-user",
  );
  assert.equal(
    result.chatId,
    deterministicChatId("sender-user", "receiver-user"),
  );
  assert.equal(result.otherUserId, "receiver-user");
});

test("rejects invalid or same-user clear requests", () => {
  assert.throws(
    () => normalizeClearChatRequest({ otherUserId: "same" }, "same"),
    /different users/,
  );
  assert.throws(
    () => normalizeClearChatRequest({ otherUserId: "" }, "actor"),
    /otherUserId/,
  );
});

test("requires exactly the two expected chat participants", () => {
  assert.equal(
    isExactPrivateChatParticipants(["receiver", "sender"], "sender", "receiver"),
    true,
  );
  assert.equal(
    isExactPrivateChatParticipants(["sender", "intruder"], "sender", "receiver"),
    false,
  );
  assert.equal(
    isExactPrivateChatParticipants(["sender", "receiver", "extra"], "sender", "receiver"),
    false,
  );
});

test("clear boundary hides messages at or before the exact cutoff only", () => {
  assert.equal(shouldHideMessageThroughClear(1000, 1000), true);
  assert.equal(shouldHideMessageThroughClear(999, 1000), true);
  assert.equal(shouldHideMessageThroughClear(1001, 1000), false);
});
