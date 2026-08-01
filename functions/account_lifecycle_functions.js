"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const { isRecentAuthentication } = require("./account_deletion_logic");
const {
  ACCOUNT_STATE_ACTIVE,
  ACCOUNT_STATE_CLOSED,
  accountState,
  closedPublicProfile,
  identityEmailKey,
  normalizeVerifiedEmail,
} = require("./account_lifecycle_logic");

const REGION = "asia-south1";
const DELETE_BATCH_LIMIT = 400;

function db() {
  return admin.firestore();
}

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function requireVerifiedEmail(request) {
  requireAuthenticatedUid(request);
  const token = (request.auth && request.auth.token) || {};
  const email = normalizeVerifiedEmail(token.email);
  if (token.email_verified !== true || !email) {
    throw new HttpsError(
      "failed-precondition",
      "A verified email is required for NearMeU identity continuity.",
    );
  }
  return email;
}

function requireRecentVerifiedIdentity(request) {
  const uid = requireAuthenticatedUid(request);
  const email = requireVerifiedEmail(request);
  if (!isRecentAuthentication(request.auth)) {
    throw new HttpsError(
      "failed-precondition",
      "Please verify your account again before closing it.",
    );
  }
  return { uid, email };
}

function identityRef(email) {
  return db().collection("identityEmails").doc(identityEmailKey(email));
}

async function claimIdentity(uid, email) {
  const ref = identityRef(email);
  await db().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (snapshot.exists && snapshot.get("ownerUid") !== uid) {
      throw new HttpsError(
        "already-exists",
        "This verified email already belongs to another NearMeU identity.",
      );
    }
    transaction.set(
      ref,
      {
        ownerUid: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function deleteAllDeviceTokensForUid(uid) {
  const profileRef = db().collection("privateProfiles").doc(uid);
  let deletedCount = 0;

  while (true) {
    const devices = await profileRef
      .collection("devices")
      .limit(DELETE_BATCH_LIMIT)
      .get();
    if (devices.empty) break;

    const batch = db().batch();
    for (const device of devices.docs) {
      batch.delete(device.ref);
      batch.delete(db().collection("deviceTokenOwners").doc(device.id));
    }
    await batch.commit();
    deletedCount += devices.size;
  }

  return deletedCount;
}

exports.ensureIdentityContinuity = onCall({ region: REGION }, async (request) => {
  const uid = requireAuthenticatedUid(request);
  const email = requireVerifiedEmail(request);
  await claimIdentity(uid, email);

  const user = await db().collection("users").doc(uid).get();
  return {
    success: true,
    accountState: user.exists ? accountState(user.data()) : ACCOUNT_STATE_ACTIVE,
  };
});

exports.closeCurrentAccount = onCall(
  { region: REGION, timeoutSeconds: 120, memory: "256MiB" },
  async (request) => {
    const { uid, email } = requireRecentVerifiedIdentity(request);
    await claimIdentity(uid, email);

    const userRef = db().collection("users").doc(uid);
    const privateRef = db().collection("privateProfiles").doc(uid);
    const userSnapshot = await userRef.get();
    if (!userSnapshot.exists) {
      throw new HttpsError("not-found", "NearMeU profile was not found.");
    }

    if (accountState(userSnapshot.data()) === ACCOUNT_STATE_CLOSED) {
      return { success: true, alreadyClosed: true };
    }

    const now = admin.firestore.Timestamp.now();
    const closedProfile = closedPublicProfile(uid, userSnapshot.data(), now);
    const batch = db().batch();
    batch.set(userRef, closedProfile);
    batch.set(
      privateRef,
      {
        exactLatitude: null,
        exactLongitude: null,
        city: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await batch.commit();

    const removedDeviceTokens = await deleteAllDeviceTokensForUid(uid);
    await admin.auth().revokeRefreshTokens(uid);

    return {
      success: true,
      alreadyClosed: false,
      removedDeviceTokens,
    };
  },
);

exports.reactivateCurrentAccount = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const email = requireVerifiedEmail(request);
    await claimIdentity(uid, email);

    const userRef = db().collection("users").doc(uid);
    const snapshot = await userRef.get();
    if (!snapshot.exists) {
      return { success: true, reactivated: false, profileRequired: true };
    }

    if (accountState(snapshot.data()) !== ACCOUNT_STATE_CLOSED) {
      return { success: true, reactivated: false, profileRequired: false };
    }

    await userRef.update({
      accountState: ACCOUNT_STATE_ACTIVE,
      closedAt: admin.firestore.FieldValue.delete(),
      reactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isOnline: false,
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, reactivated: true, profileRequired: true };
  },
);
