const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();

exports.testConnection = onCall(async () => {
  return {
    success: true,
    message: "NearMeU Cloud Functions Working"
  };
});

exports.getServerTime = onCall(async () => {
  return {
    timestamp: Date.now()
  };
});