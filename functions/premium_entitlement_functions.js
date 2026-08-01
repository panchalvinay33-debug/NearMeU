"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const {
  evaluatePremiumEntitlement,
} = require("./premium_entitlement_logic");

const db = admin.firestore();
const REGION = "asia-south1";

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

async function readPremiumEntitlement(uid) {
  const snapshot = await db.collection("premiumEntitlements").doc(uid).get();
  return evaluatePremiumEntitlement(snapshot.exists ? snapshot.data() : null);
}

function requirePremiumEntitlement(entitlement, feature) {
  if (entitlement && entitlement.isPremium === true) return;
  throw new HttpsError(
    "failed-precondition",
    "Premium is required for this action.",
    { reason: "premium-required", feature },
  );
}

exports.getMyPremiumEntitlement = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    return readPremiumEntitlement(uid);
  },
);

module.exports.readPremiumEntitlement = readPremiumEntitlement;
module.exports.requirePremiumEntitlement = requirePremiumEntitlement;
