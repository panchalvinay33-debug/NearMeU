"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const indexSource = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");
const protectedCallables = [
  "registerDeviceToken",
  "unregisterDeviceToken",
  "unregisterAllDeviceTokens",
  "deleteCurrentAccount",
];

test("callable wrapper enables App Check enforcement", () => {
  assert.match(
    indexSource,
    /function appCheckedCall[\s\S]*enforceAppCheck:\s*true/,
  );
});

for (const callable of protectedCallables) {
  test(`${callable} uses the App Check wrapper`, () => {
    assert.match(
      indexSource,
      new RegExp(`exports\\.${callable}\\s*=\\s*appCheckedCall\\s*\\(`),
    );
    assert.doesNotMatch(
      indexSource,
      new RegExp(`exports\\.${callable}\\s*=\\s*onCall\\s*\\(`),
    );
  });
}
