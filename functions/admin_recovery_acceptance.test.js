"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

function read(name) {
  return fs.readFileSync(path.join(__dirname, name), "utf8");
}

test("A05 recovery health stays App Check exported and permission gated", () => {
  const bootstrap = read("bootstrap.js");
  const functions = read("admin_recovery_functions.js");
  assert.match(bootstrap, /setGlobalOptions\(\{ enforceAppCheck: true \}\)/);
  assert.match(bootstrap, /admin_recovery_functions\.js/);
  assert.match(functions, /const getAdminRecoveryHealth = onCall/);
  assert.match(functions, /requireAdmin\(request, "recovery\.read"\)/);
});

test("A05 returns aggregate health only and forbids recovery content browser", () => {
  const functions = read("admin_recovery_functions.js");
  assert.match(functions, /contentBrowser: false/);
  assert.match(functions, /messageTextIncluded: false/);
  assert.match(functions, /mediaPathsIncluded: false/);
  assert.match(functions, /userRecoveryLookup: false/);
  assert.doesNotMatch(functions, /getMyPremiumRecoveryPage/);
  assert.doesNotMatch(functions, /recoveryMediaStoragePath\s*:/);
  assert.doesNotMatch(functions, /text\s*:/);
});

test("A05 production deploy remains scoped to recovery health callable", () => {
  const deploy = fs.readFileSync(
    path.join(__dirname, "..", "tool", "deploy_admin_a05.ps1"),
    "utf8",
  );
  assert.match(deploy, /FUNCTIONS_DISCOVERY_TIMEOUT = '60'/);
  assert.match(deploy, /functions:getAdminRecoveryHealth/);
  assert.doesNotMatch(deploy, /--only 'functions'\s*$/m);
});
