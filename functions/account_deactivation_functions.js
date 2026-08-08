"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { isRecentAuthentication } = require("./account_deletion_logic");

const db = admin.firestore();
const REGION = "asia-south1";

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  return uid;
}

function requireRecentAuthentication(request) {
  const uid = requireAuthenticatedUid(request);
  if (!isRecentAuthentication(request.auth)) {
    throw new HttpsError(
      "failed-precondition",
      "Please verify your account again before deactivating it.",
    );
  }
  return uid;
}

exports.deactivateCurrentAccount = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireRecentAuthentication(request);
    const userRef = db.collection("users").doc(uid);
    const snapshot = await userRef.get();

    if (!snapshot.exists) {
      throw new HttpsError("not-found", "NearMeU profile was not found.");
    }
    if (snapshot.get("isAdmin") === true) {
      throw new HttpsError(
        "failed-precondition",
        "The owner administrator account cannot be deactivated from the app.",
      );
    }
    if (snapshot.get("isSuspended") === true) {
      throw new HttpsError(
        "failed-precondition",
        "A suspended account cannot be self-deactivated.",
      );
    }

    if (snapshot.get("isDeactivated") === true) {
      return { success: true, alreadyDeactivated: true };
    }

    await userRef.set(
      {
        isDeactivated: true,
        isOnline: false,
        deactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { success: true, alreadyDeactivated: false };
  },
);

exports.reactivateCurrentAccount = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const userRef = db.collection("users").doc(uid);
    const snapshot = await userRef.get();

    if (!snapshot.exists) {
      return { success: true, reactivated: false, profileRequired: true };
    }
    if (snapshot.get("isSuspended") === true) {
      throw new HttpsError("permission-denied", "This account is suspended.");
    }
    if (snapshot.get("isDeactivated") !== true) {
      return { success: true, reactivated: false, profileRequired: false };
    }

    await userRef.set(
      {
        isDeactivated: false,
        isOnline: false,
        reactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { success: true, reactivated: true, profileRequired: false };
  },
);
