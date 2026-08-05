"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const source = fs.readFileSync(
  path.join(__dirname, "audio_call_r2_incoming_functions.js"),
  "utf8",
);
const bootstrap = fs.readFileSync(path.join(__dirname, "bootstrap.js"), "utf8");

test("foreground incoming lookup is isolated to R2 collections", () => {
  assert.match(source, /collection\("activeAudioCallsR2"\)/);
  assert.match(source, /collection\("audioCallsR2"\)/);
  assert.doesNotMatch(source, /collection\("activeAudioCalls"\)/);
  assert.doesNotMatch(source, /collection\("audioCalls"\)/);
});

test("only the callee of a live ringing call is returned", () => {
  assert.match(source, /role !== "callee"/);
  assert.match(source, /call\.status !== "ringing"/);
  assert.match(source, /ringExpiresAtMillis/);
  assert.match(source, /return null/);
});

test("incoming lookup exposes no RTC credential or notification integration", () => {
  assert.doesNotMatch(source, /AGORA_APP_/);
  assert.doesNotMatch(source, /RtcTokenBuilder/);
  assert.doesNotMatch(source, /admin\.messaging/);
  assert.doesNotMatch(source, /sendEachForMulticast/);
});

test("bootstrap exports the foreground incoming callable", () => {
  assert.match(source, /exports\.getIncomingAudioCallR2\s*=/);
  assert.match(bootstrap, /audio_call_r2_incoming_functions\.js/);
});
