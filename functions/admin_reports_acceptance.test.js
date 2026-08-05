"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

function read(name) {
  return fs.readFileSync(path.join(__dirname, name), "utf8");
}

test("A04 moderation callable contract stays App Check exported and permission gated", () => {
  const bootstrap = read("bootstrap.js");
  const functions = read("admin_reports_functions.js");

  assert.match(bootstrap, /setGlobalOptions\(\{ enforceAppCheck: true \}\)/);
  assert.match(bootstrap, /admin_reports_functions\.js/);

  for (const callable of [
    "listAdminReports",
    "getAdminReportDetail",
    "setAdminReportDecision",
  ]) {
    assert.match(functions, new RegExp(`const ${callable} = onCall`));
  }

  assert.equal(
    (functions.match(/requireAdmin\(request, "safety\.review"\)/g) || []).length,
    3,
  );
});

test("A04 report detail explicitly excludes unrestricted private context", () => {
  const functions = read("admin_reports_functions.js");
  const logic = read("admin_reports_logic.js");

  assert.match(functions, /unrestrictedChatAccess: false/);
  assert.match(functions, /exactLocationAccess: false/);
  assert.match(functions, /privateProfileAccess: false/);
  assert.match(functions, /messageContentIncluded: false/);
  assert.doesNotMatch(functions, /collection\("privateProfiles"\)/);
  assert.doesNotMatch(functions, /collection\("chats"\)/);
  assert.doesNotMatch(functions, /collection\("messages"\)/);
  assert.doesNotMatch(logic, /exactLocation:/);
  assert.doesNotMatch(logic, /privateChat:/);
});

test("A04 keeps report evidence and exposes decisions without delete callable", () => {
  const functions = read("admin_reports_functions.js");
  const logic = read("admin_reports_logic.js");

  assert.match(logic, /"resolved", "dismissed", "pending"/);
  assert.match(functions, /safety\.report\.decision/);
  assert.match(functions, /normalizeDecisionNote/);
  assert.doesNotMatch(functions, /deleteAdminReport/);
  assert.doesNotMatch(functions, /transaction\.delete\(ref\)/);
  assert.doesNotMatch(functions, /\.doc\(reportId\)\.delete\(\)/);
});

test("A04 production deploy script is scoped to the three report callables", () => {
  const deploy = fs.readFileSync(
    path.join(__dirname, "..", "tool", "deploy_admin_a04.ps1"),
    "utf8",
  );

  assert.match(deploy, /FUNCTIONS_DISCOVERY_TIMEOUT = '60'/);
  assert.match(
    deploy,
    /functions:listAdminReports,functions:getAdminReportDetail,functions:setAdminReportDecision/,
  );
  assert.doesNotMatch(deploy, /--only 'functions'\s*$/m);
});
