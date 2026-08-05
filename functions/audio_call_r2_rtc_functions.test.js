"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const source = fs.readFileSync(
  path.join(__dirname, "audio_call_r2_rtc_functions.js"),
  "utf8",
);
const bootstrap = fs.readFileSync(path.join(__dirname, "bootstrap.js"), "utf8");
const pkg = JSON.parse(
  fs.readFileSync(path.join(__dirname, "package.json"), "utf8"),
);

test("R2-A2 uses the exact tested Agora token dependency", () => {
  assert.equal(pkg.dependencies["agora-token"], "2.0.5");
  assert.match(source, /require\("agora-token"\)/);
});

test("RTC access is isolated and exported separately", () => {
  assert.match(source, /exports\.getAudioRtcAccessR2\s*=/);
  assert.match(bootstrap, /audio_call_r2_rtc_functions\.js/);
  assert.doesNotMatch(source, /admin\.messaging\(/);
  assert.doesNotMatch(source, /sendEachForMulticast/);
});

test("Agora secrets come only from Firebase Secret Manager", () => {
  assert.match(source, /defineSecret\("AGORA_APP_ID"\)/);
  assert.match(source, /defineSecret\("AGORA_APP_CERTIFICATE"\)/);
  assert.match(source, /secrets:\s*\[AGORA_APP_ID, AGORA_APP_CERTIFICATE\]/);
  assert.match(source, /AGORA_CREDENTIAL_PATTERN/);
  assert.doesNotMatch(source, /AGORA_APP_ID\s*=\s*["'][a-fA-F0-9]{32}["']/);
  assert.doesNotMatch(source, /AGORA_APP_CERTIFICATE\s*=\s*["'][a-fA-F0-9]{32}["']/);
});

test("only valid participants in an active call can receive RTC access", () => {
  assert.match(source, /participantRole\(call, uid\)/);
  assert.match(source, /permission-denied/);
  assert.match(source, /isTerminalStatus\(call\.status\)/);
  assert.match(source, /role === "callee" && call\.status !== "accepted"/);
  assert.match(source, /blockedEitherWay\(uid, otherUid\)/);
  assert.match(source, /ringExpiresAtMillis/);
  assert.match(source, /expiresAtMillis/);
});

test("RTC token is short lived and server generated", () => {
  assert.match(source, /RTC_TOKEN_SECONDS = 2 \* 60 \* 60/);
  assert.match(source, /RtcTokenBuilder\.buildTokenWithUid/);
  assert.match(source, /RtcRole\.PUBLISHER/);
  assert.match(source, /agoraUidFromFirebaseUid\(uid\)/);
  assert.match(source, /channelNameForCall\(callId\)/);
});
