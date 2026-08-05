"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildBusinessMetrics,
  normalizeCount,
  percent,
} = require("./admin_business_logic");

test("normalizeCount rejects invalid and negative values", () => {
  assert.equal(normalizeCount(-4), 0);
  assert.equal(normalizeCount(Number.NaN), 0);
  assert.equal(normalizeCount(12.9), 12);
});

test("percent is safe for zero totals and rounds to one decimal", () => {
  assert.equal(percent(5, 0), 0);
  assert.equal(percent(1, 3), 33.3);
});

test("business metrics calculate bounded aggregate rates", () => {
  const result = buildBusinessMetrics({
    totalUsers: 100,
    onlineUsers: 12,
    suspendedUsers: 3,
    newUsers24h: 4,
    newUsers7d: 28,
    newUsers30d: 90,
    premiumRecords: 25,
    googlePlayMarkedActive: 17,
    adminMarkedActive: 6,
  });

  assert.deepEqual(result.users, {
    total: 100,
    onlineMarked: 12,
    suspended: 3,
    new24h: 4,
    new7d: 28,
    new30d: 90,
  });
  assert.deepEqual(result.premium, {
    entitlementRecords: 25,
    googlePlayMarkedActive: 17,
    adminMarkedActive: 6,
  });
  assert.equal(result.rates.onlineSharePct, 12);
  assert.equal(result.rates.suspendedSharePct, 3);
  assert.equal(result.rates.avgDailyNewUsers7d, 4);
  assert.equal(result.rates.avgDailyNewUsers30d, 3);
  assert.equal(result.rates.sevenDayVsThirtyDayPacePct, 133.3);
});
