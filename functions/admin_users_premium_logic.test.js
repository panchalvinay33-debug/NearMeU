"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  normalizeLookupQuery,
  normalizeUid,
  normalizeReason,
  normalizePremiumDays,
  premiumExpiryMillis,
} = require("./admin_users_premium_logic");

test("lookup query trims valid values and rejects empty/oversized values", () => {
  assert.equal(normalizeLookupQuery("  abc@example.com  "), "abc@example.com");
  assert.equal(normalizeLookupQuery(""), null);
  assert.equal(normalizeLookupQuery("x".repeat(321)), null);
});

test("uid validation rejects whitespace and empty values", () => {
  assert.equal(normalizeUid("  uid-123  "), "uid-123");
  assert.equal(normalizeUid("uid 123"), null);
  assert.equal(normalizeUid(""), null);
});

test("reason validation enforces required and length limits", () => {
  assert.equal(normalizeReason("  policy review  ", { required: true }), "policy review");
  assert.equal(normalizeReason("", { required: true }), null);
  assert.equal(normalizeReason(null), "");
  assert.equal(normalizeReason("x".repeat(301)), null);
});

test("premium duration is deliberately limited to approved presets", () => {
  for (const days of [7, 30, 90, 365]) assert.equal(normalizePremiumDays(days), days);
  for (const days of [0, 1, 366, 30.5, "30"]) assert.equal(normalizePremiumDays(days), null);
});

test("premium expiry calculation is deterministic", () => {
  const now = 1_000_000;
  assert.equal(premiumExpiryMillis(7, now), now + 7 * 24 * 60 * 60 * 1000);
});
