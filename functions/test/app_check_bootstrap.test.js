"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const functionsRoot = path.resolve(__dirname, "..");

test("Firebase deploy entrypoint uses the App Check bootstrap", () => {
  const packageJson = JSON.parse(
    fs.readFileSync(path.join(functionsRoot, "package.json"), "utf8"),
  );

  assert.equal(packageJson.main, "bootstrap.js");
});

test("App Check is enforced before function definitions are loaded", () => {
  const bootstrap = fs.readFileSync(
    path.join(functionsRoot, "bootstrap.js"),
    "utf8",
  );

  const enforcementIndex = bootstrap.indexOf(
    "setGlobalOptions({ enforceAppCheck: true })",
  );
  const definitionsIndex = bootstrap.indexOf('require("./index.js")');

  assert.notEqual(enforcementIndex, -1);
  assert.notEqual(definitionsIndex, -1);
  assert.ok(enforcementIndex < definitionsIndex);
});
