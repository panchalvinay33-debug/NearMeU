"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const { isRecentAuthentication } = require("./account_deletion_logic");
const {
  ACCOUNT_STATE_ACTIVE,
  ACCOUNT_STATE_CLOSED,
  accountState,
  closedLifecycleRecord,
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

function lifecycleRef(uid) {
  return db().collection("accountLifecycle").doc(uid);
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

  const lifecycle = await lifecycleRef(uid).get();
  return {
    success: true,
    accountState: lifecycle.exists
      ? accountState(lifecycle.data())
      : ACCOUNT_STATE_ACTIVE,
  };
});

exports.closeCurrentAccount = onCall(
  { region: REGION, timeoutSeconds: 120, memory: "256MiB" },
  async (request) => {
    const { uid, email } = requireRecentVerifiedIdentity(request);
    await claimIdentity(uid, email);

    const userRef = db().collection("users").doc(uid);
    const privateRef = db().collection("privateProfiles").doc(uid);
    const stateRef = lifecycleRef(uid);
    const [userSnapshot, lifecycleSnapshot] = await Promise.all([
      userRef.get(),
      stateRef.get(),
    ]);

    if (
      lifecycleSnapshot.exists &&
      accountState(lifecycleSnapshot.data()) === ACCOUNT_STATE_CLOSED
    ) {
      return { success: true, alreadyClosed: true };
    }
    if (!userSnapshot.exists) {
      throw new HttpsError("not-found", "NearMeU profile was not found.");
    }

    const userData = userSnapshot.data() || {};
    if (userData.isAdmin === true) {
      throw new HttpsError(
        "failed-precondition",
        "The owner administrator account cannot be closed from the app.",
      );
    }
    if (userData.isSuspended === true) {
      throw new HttpsError(
        "failed-precondition",
        "A suspended account cannot be self-closed.",
      );
    }

    const now = admin.firestore.Timestamp.now();
    const batch = db().batch();

    // Deleting only the public parent document makes the account immediately
    // unavailable to discovery and to every rule/function that requires an
    // active users/{uid} document. Firestore subcollections are NOT deleted,
    // so block relationships survive exactly as required by the product rule.
    batch.delete(userRef);
    batch.set(stateRef, {
      ...closedLifecycleRecord(uid, userData, now),
      identityKey: identityEmailKey(email),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
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

    // The lifecycle transaction above is authoritative. Cleanup after it is
    // best-effort: if token deletion or refresh-token revocation temporarily
    // fails, the closed account must stay closed rather than surfacing a false
    // failure to the client. Existing authorization already fails closed
    // because users/{uid} no longer exists.
    let removedDeviceTokens = 0;
    let cleanupPending = false;
    try {
      removedDeviceTokens = await deleteAllDeviceTokensForUid(uid);
    } catch (_) {
      cleanupPending = true;
    }
    try {
      await admin.auth().revokeRefreshTokens(uid);
    } catch (_) {
      cleanupPending = true;
    }

    return {
      success: true,
      alreadyClosed: false,
      removedDeviceTokens,
      cleanupPending,
    };
  },
);

exports.reactivateCurrentAccount = onCall(
  { region: REGION, timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const email = requireVerifiedEmail(request);
    await claimIdentity(uid, email);

    const stateRef = lifecycleRef(uid);
    const snapshot = await stateRef.get();
    if (!snapshot.exists || accountState(snapshot.data()) !== ACCOUNT_STATE_CLOSED) {
      const user = await db().collection("users").doc(uid).get();
      return {
        success: true,
        reactivated: false,
        profileRequired: !user.exists,
      };
    }

    const stateData = snapshot.data() || {};
    if (stateData.identityKey && stateData.identityKey !== identityEmailKey(email)) {
      throw new HttpsError(
        "permission-denied",
        "Reactivation requires the same verified email used by this identity.",
      );
    }

    await stateRef.set(
      {
        accountState: ACCOUNT_STATE_ACTIVE,
        reactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { success: true, reactivated: true, profileRequired: true };
  },
);
