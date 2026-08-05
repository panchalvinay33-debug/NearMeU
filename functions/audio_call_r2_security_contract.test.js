"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const rules = fs.readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8");
const source = fs.readFileSync(
  path.join(__dirname, "audio_call_r2_functions.js"),
  "utf8",
);

test("R2 call state has no direct client allow rule", () => {
  assert.doesNotMatch(rules, /match\s+\/audioCallsR2\//);
  assert.doesNotMatch(rules, /match\s+\/activeAudioCallsR2\//);
  assert.match(rules, /match\s+\/\{document=\*\*\}/);
  assert.match(rules, /allow\s+read,\s*write:\s*if\s*false/);
});

test("R2 lifecycle state is written only by trusted backend module", () => {
  assert.match(source, /collection\("audioCallsR2"\)/);
  assert.match(source, /collection\("activeAudioCallsR2"\)/);
  assert.match(source, /onCall\(/);
  assert.match(source, /onSchedule\(/);
});
