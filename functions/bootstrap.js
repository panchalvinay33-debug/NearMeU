"use strict";

const { setGlobalOptions } = require("firebase-functions/v2");

// Every HTTPS/callable function rejects requests that do not carry a valid
// Firebase App Check token. Firestore and scheduled event handlers are not
// client-invoked, so the SDK does not apply this option to those triggers.
setGlobalOptions({ enforceAppCheck: true });

module.exports = {
  ...require("./index.js"),
  ...require("./anti_abuse_functions.js"),
  ...require("./trusted_read_functions.js"),
};
