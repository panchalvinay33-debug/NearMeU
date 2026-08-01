"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  evaluatePremiumEntitlement,
} = require("./premium_entitlement_logic");

test("missing entitlement is Free", () => {
  assert.deepEqual(evaluatePremiumEntitlement(null, 1_000), {
    schemaVersion: 1,
    plan: "free",
    isPremium: false,
    activeSources: [],
    expiresAtMillis: null,
  });
});

test("active Google Play grant enables Premium", () => {
  const result = evaluatePremiumEntitlement({
    grants: {
      googlePlay: { active: true, expiresAt: 2_000 },
    },
  }, 1_000);
  assert.equal(result.isPremium, true);
  assert.equal(result.plan, "premium");
  assert.deepEqual(result.activeSources, ["googlePlay"]);
  assert.equal(result.expiresAtMillis, 2_000);
});

test("expired grant is ignored", () => {
  const result = evaluatePremiumEntitlement({
    grants: {
      googlePlay: { active: true, expiresAt: 999 },
    },
  }, 1_000);
  assert.equal(result.isPremium, false);
});

test("admin grant and Google Play grant coexist independently", () => {
  const result = evaluatePremiumEntitlement({
    grants: {
      googlePlay: { active: true, expiresAt: 3_000 },
      admin: { active: true, expiresAt: 2_000 },
    },
  }, 1_000);
  assert.equal(result.isPremium, true);
  assert.deepEqual(result.activeSources, ["googlePlay", "admin"]);
  assert.equal(result.expiresAtMillis, 3_000);
});

test("non-expiring active grant makes effective expiry open-ended", () => {
  const result = evaluatePremiumEntitlement({
    grants: {
      googlePlay: { active: true, expiresAt: 3_000 },
      admin: { active: true, expiresAt: null },
    },
  }, 1_000);
  assert.equal(result.isPremium, true);
  assert.equal(result.expiresAtMillis, null);
});
