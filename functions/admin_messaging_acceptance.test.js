"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = __dirname;
const source = fs.readFileSync(path.join(root, "admin_messaging_functions.js"), "utf8");
const bootstrap = fs.readFileSync(path.join(root, "bootstrap.js"), "utf8");
const deploy = fs.readFileSync(path.join(root, "..", "tool", "deploy_admin_a06.ps1"), "utf8");
const indexes = fs.readFileSync(path.join(root, "..", "firestore.indexes.json"), "utf8");

test("A06 callable is globally App Check protected and exported", () => {
  assert.match(bootstrap, /enforceAppCheck:\s*true/);
  assert.match(bootstrap, /admin_messaging_functions/);
  assert.match(source, /onCall\(\{ region: REGION \}/);
});

test("A06 requires only messaging.readHealth and writes immutable audit evidence", () => {
  assert.match(source, /requireAdmin\(request, "messaging\.readHealth"\)/);
  assert.match(source, /messaging\.health\.read/);
});

test("A06 query uses bounded metadata projection and excludes private content", () => {
  assert.match(source, /\.select\(/);
  assert.match(source, /\.limit\(SAMPLE_LIMIT\)/);
  assert.doesNotMatch(source, /\.select\([^)]*"text"/s);
  assert.doesNotMatch(source, /\.select\([^)]*"senderId"/s);
  assert.doesNotMatch(source, /\.select\([^)]*"receiverId"/s);
  assert.doesNotMatch(source, /\.select\([^)]*"mediaUrl"/s);
  assert.doesNotMatch(source, /\.select\([^)]*"mediaStoragePath"/s);
  assert.match(source, /messageTextIncluded:\s*false/);
  assert.match(source, /senderReceiverIdsIncluded:\s*false/);
  assert.match(source, /callRecordingsIncluded:\s*false/);
});

test("A06 declares collection-group timestamp index and scoped deploy", () => {
  assert.match(indexes, /"fieldPath": "timestamp"/);
  assert.match(indexes, /"queryScope": "COLLECTION_GROUP"/);
  assert.match(deploy, /firestore:indexes/);
  assert.match(deploy, /functions:getAdminMessagingHealth/);
  assert.doesNotMatch(deploy, /--only\s+['"]functions['"]/);
});
