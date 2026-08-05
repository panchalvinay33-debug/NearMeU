"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { buildRecoveryHealthMetrics, percent } = require("./admin_recovery_logic");

test("percent is bounded and zero-safe", () => {
  assert.equal(percent(5, 10), 50);
  assert.equal(percent(1, 3), 33.33);
  assert.equal(percent(0, 0), 0);
});

test("recovery health metrics preserve independent delivery and premium counters", () => {
  const metrics = buildRecoveryHealthMetrics({
    deliveryActive: 90,
    deliveryExpiredBacklog: 10,
    deliveryExpiring24h: 12,
    premiumRecoveryUsers: 7,
    premiumRecoveryActive: 45,
    premiumRecoveryExpiredBacklog: 5,
    premiumRecoveryExpiring7d: 8,
  });
  assert.equal(metrics.delivery.activeStampedMessages, 90);
  assert.equal(metrics.delivery.expiredBacklog, 10);
  assert.equal(metrics.delivery.expiredBacklogRatePct, 10);
  assert.equal(metrics.premiumRecovery.userRecords, 7);
  assert.equal(metrics.premiumRecovery.activeRetainedMessages, 45);
  assert.equal(metrics.premiumRecovery.expiredBacklogRatePct, 10);
});
