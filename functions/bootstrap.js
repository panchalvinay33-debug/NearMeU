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
  ...require("./chat_read_functions.js"),
  ...require("./delivery_receipt_functions.js"),
  ...require("./message_retention_functions.js"),
  ...require("./premium_entitlement_functions.js"),
  ...require("./premium_recovery_functions.js"),
  ...require("./premium_recovery_delete_functions.js"),
  ...require("./premium_recovery_account_cleanup_functions.js"),
  ...require("./private_media_functions.js"),
  ...require("./private_media_ack_functions.js"),
  ...require("./message_unsend_functions.js"),
  ...require("./chat_clear_functions.js"),
  ...require("./account_lifecycle_functions.js"),
  ...require("./profile_sharing_functions.js"),
  ...require("./announcement_media_functions.js"),
  ...require("./announcement_push_functions.js"),
  ...require("./app_version_functions.js"),
  ...require("./admin_session_functions.js"),
  ...require("./admin_business_functions.js"),
  ...require("./admin_reports_functions.js"),
};
