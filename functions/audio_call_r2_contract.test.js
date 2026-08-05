"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const source = fs.readFileSync(
  path.join(__dirname, "audio_call_r2_functions.js"),
  "utf8",
);
const bootstrap = fs.readFileSync(path.join(__dirname, "bootstrap.js"), "utf8");

test("R2-A1 is isolated from old Batch 09 collections", () => {
  assert.match(source, /collection\("audioCallsR2"\)/);
  assert.match(source, /collection\("activeAudioCallsR2"\)/);
  assert.doesNotMatch(source, /collection\("audioCalls"\)/);
  assert.doesNotMatch(source, /collection\("activeAudioCalls"\)/);
});

test("R2-A1 contains no notification or Agora SDK integration yet", () => {
  assert.doesNotMatch(source, /admin\.messaging\(/);
  assert.doesNotMatch(source, /sendEachForMulticast/);
  assert.doesNotMatch(source, /agora-token/);
  assert.doesNotMatch(source, /RtcTokenBuilder/);
});

test("R2-A1 exposes only lifecycle functions through bootstrap", () => {
  assert.match(bootstrap, /audio_call_r2_functions\.js/);
  for (const name of [
    "startAudioCallR2",
    "getAudioCallR2",
    "respondAudioCallR2",
    "endAudioCallR2",
    "expireStaleAudioCallsR2",
  ]) {
    assert.match(source, new RegExp(`exports\\.${name}\\s*=`));
  }
});

test("Premium initiation and bidirectional blocking stay server-side", () => {
  assert.match(source, /requirePremiumEntitlement\(entitlement, "audio-call-initiation"\)/);
  assert.match(source, /blockedEitherWay\(callerUid, calleeUid\)/);
  assert.match(source, /blockedEitherWay\(uid, otherUid\)/);
});
