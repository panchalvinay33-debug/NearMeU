"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { buildMessagingHealthMetrics, percent } = require("./admin_messaging_logic");

test("percent is bounded and zero-safe", () => {
  assert.equal(percent(0, 0), 0);
  assert.equal(percent(1, 4), 25);
  assert.equal(percent(2, 3), 66.67);
});

test("messaging metrics aggregate operational metadata only", () => {
  const result = buildMessagingHealthMetrics([
    { type: "text", isDelivered: true, isSeen: false, isUnsent: false },
    { type: "image", isDelivered: true, isSeen: true, mediaSizeBytes: 1200 },
    { type: "voice", isSeen: true, mediaSizeBytes: 800, mediaDurationMs: 5000 },
    { type: "video", cloudMediaDeletePending: true, mediaSizeBytes: 2000, isUnsent: true },
  ]);

  assert.equal(result.sampledMessages, 4);
  assert.equal(result.deliveredMessages, 3);
  assert.equal(result.seenMessages, 2);
  assert.equal(result.unsentMessages, 1);
  assert.equal(result.deliveryRatePercent, 75);
  assert.equal(result.seenRatePercent, 50);
  assert.deepEqual(result.types, { text: 1, image: 1, video: 1, voice: 1, other: 0 });
  assert.equal(result.mediaMessages, 3);
  assert.equal(result.mediaBytes, 4000);
  assert.equal(result.voiceMessages, 1);
  assert.equal(result.voiceDurationMs, 5000);
  assert.equal(result.pendingMediaCleanup, 1);
});

test("unknown types and invalid numeric metadata fail safe", () => {
  const result = buildMessagingHealthMetrics([
    { type: "future", mediaSizeBytes: -4, mediaDurationMs: "10" },
  ]);
  assert.equal(result.types.other, 1);
  assert.equal(result.mediaBytes, 0);
  assert.equal(result.voiceDurationMs, 0);
});
