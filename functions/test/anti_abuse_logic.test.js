"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  MAX_MESSAGES_PER_WINDOW,
  MAX_REPORTS_PER_WINDOW,
  MESSAGE_WINDOW_MS,
  MIN_MESSAGE_INTERVAL_MS,
  REPORT_REPEAT_COOLDOWN_MS,
  REPORT_WINDOW_MS,
  isWithinReportCooldown,
  messageRateDecision,
  normalizedMessage,
  normalizedReply,
  normalizedReport,
  reportRateDecision,
} = require("../anti_abuse_logic");

test("normalizes message text and rejects empty or oversized payloads", () => {
  assert.equal(normalizedMessage("  hello  "), "hello");
  assert.throws(() => normalizedMessage("   "), /cannot be empty/i);
  assert.throws(() => normalizedMessage("x".repeat(1001)), /longer than 1000/i);
});

test("validates reply metadata against the two chat participants", () => {
  assert.deepEqual(
    normalizedReply(
      { messageId: "m1", text: "hello", senderId: "alice" },
      ["alice", "bob"],
    ),
    { messageId: "m1", text: "hello", senderId: "alice" },
  );
  assert.throws(
    () => normalizedReply(
      { messageId: "m1", text: "hello", senderId: "mallory" },
      ["alice", "bob"],
    ),
    /not a chat participant/i,
  );
});

test("enforces minimum message interval before the rolling window", () => {
  const nowMs = 10_000;
  const decision = messageRateDecision({
    nowMs,
    lastMessageAtMs: nowMs - MIN_MESSAGE_INTERVAL_MS + 1,
    windowStartedAtMs: nowMs - 5_000,
    count: 2,
  });
  assert.equal(decision.allowed, false);
  assert.equal(decision.reason, "minimum_interval");
  assert.equal(decision.retryAfterMs, 1);
});

test("allows thirty messages per minute and rejects the next one", () => {
  const nowMs = 20_000;
  const allowed = messageRateDecision({
    nowMs,
    lastMessageAtMs: nowMs - MIN_MESSAGE_INTERVAL_MS,
    windowStartedAtMs: nowMs - 10_000,
    count: MAX_MESSAGES_PER_WINDOW - 1,
  });
  assert.equal(allowed.allowed, true);
  assert.equal(allowed.count, MAX_MESSAGES_PER_WINDOW);

  const denied = messageRateDecision({
    nowMs: nowMs + MIN_MESSAGE_INTERVAL_MS,
    lastMessageAtMs: nowMs,
    windowStartedAtMs: nowMs - 10_000,
    count: MAX_MESSAGES_PER_WINDOW,
  });
  assert.equal(denied.allowed, false);
  assert.equal(denied.reason, "window_limit");
});

test("message window resets after one minute", () => {
  const decision = messageRateDecision({
    nowMs: MESSAGE_WINDOW_MS + 100,
    lastMessageAtMs: 0,
    windowStartedAtMs: 0,
    count: MAX_MESSAGES_PER_WINDOW,
  });
  assert.equal(decision.allowed, true);
  assert.equal(decision.count, 1);
  assert.equal(decision.windowStartedAtMs, MESSAGE_WINDOW_MS + 100);
});

test("report payload requires a valid reason and an explanation for Other", () => {
  assert.deepEqual(normalizedReport("Spam", "  repeated links "), {
    reason: "Spam",
    description: "repeated links",
  });
  assert.throws(() => normalizedReport("Unknown", ""), /reason is invalid/i);
  assert.throws(() => normalizedReport("Other", ""), /describe the problem/i);
});

test("allows five reports per day and rejects the sixth", () => {
  const nowMs = 100_000;
  const allowed = reportRateDecision({
    nowMs,
    windowStartedAtMs: nowMs - 1_000,
    count: MAX_REPORTS_PER_WINDOW - 1,
  });
  assert.equal(allowed.allowed, true);
  assert.equal(allowed.count, MAX_REPORTS_PER_WINDOW);

  const denied = reportRateDecision({
    nowMs,
    windowStartedAtMs: nowMs - 1_000,
    count: MAX_REPORTS_PER_WINDOW,
  });
  assert.equal(denied.allowed, false);
  assert.ok(denied.retryAfterMs <= REPORT_WINDOW_MS);
});

test("applies a seven-day repeated-report cooldown", () => {
  const nowMs = REPORT_REPEAT_COOLDOWN_MS + 10;
  assert.equal(
    isWithinReportCooldown(nowMs, nowMs - REPORT_REPEAT_COOLDOWN_MS + 1),
    true,
  );
  assert.equal(
    isWithinReportCooldown(nowMs, nowMs - REPORT_REPEAT_COOLDOWN_MS),
    false,
  );
});
