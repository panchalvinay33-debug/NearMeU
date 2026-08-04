"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");
const { evaluatePremiumEntitlement } = require("./premium_entitlement_logic");
const {
  normalizeLookupQuery,
  normalizeUid,
  normalizeReason,
  normalizePremiumDays,
  premiumExpiryMillis,
  safeTimestampMillis,
} = require("./admin_users_premium_logic");

const REGION = "asia-south1";
const db = admin.firestore();
const auth = admin.auth();

function requireAdmin(request, permission = null) {
  const result = evaluateAdminAuthorization(request.auth, permission);
  if (!result.ok) {
    const message = result.code === "unauthenticated"
      ? "Authentication required."
      : "Admin authorization required.";
    throw new HttpsError(result.code, message);
  }
  return result.actor;
}

async function writeAudit(actor, action, details = {}) {
  await db.collection("adminAudit").add({
    actorUid: actor.uid,
    actorRole: actor.role,
    action,
    details,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAtIso: new Date().toISOString(),
  });
}

async function resolveAuthUser(rawQuery) {
  const query = normalizeLookupQuery(rawQuery);
  if (!query) {
    throw new HttpsError("invalid-argument", "Enter a valid UID or email address.");
  }
  try {
    return query.includes("@")
      ? await auth.getUserByEmail(query)
      : await auth.getUser(query);
  } catch (error) {
    if (error && error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "User not found.");
    }
    throw error;
  }
}

function assertTargetIsNotAdmin(userRecord) {
  const role = userRecord && userRecord.customClaims
    ? userRecord.customClaims.nearmeuAdminRole
    : null;
  if (role === "owner" || role === "admin") {
    throw new HttpsError(
      "failed-precondition",
      "Owner/Admin accounts cannot be changed through consumer user controls.",
    );
  }
}

function publicUserSnapshot(uid, data, authUser, premium) {
  const safe = data && typeof data === "object" ? data : {};
  return {
    uid,
    email: authUser.email || null,
    emailVerified: authUser.emailVerified === true,
    authDisabled: authUser.disabled === true,
    nickname: typeof safe.nickname === "string" ? safe.nickname : null,
    age: Number.isInteger(safe.age) ? safe.age : null,
    gender: typeof safe.gender === "string" ? safe.gender : null,
    lookingFor: typeof safe.lookingFor === "string" ? safe.lookingFor : null,
    state: typeof safe.state === "string" ? safe.state : null,
    country: typeof safe.country === "string" ? safe.country : null,
    photoUrl: typeof safe.photoUrl === "string" ? safe.photoUrl : null,
    isOnline: safe.isOnline === true,
    isSuspended: safe.isSuspended === true,
    createdAtMillis: safeTimestampMillis(safe.createdAt),
    lastSeenMillis: safeTimestampMillis(safe.lastSeen),
    suspension: safe.suspension && typeof safe.suspension === "object"
      ? {
          reason: typeof safe.suspension.reason === "string" ? safe.suspension.reason : null,
          updatedAtMillis: safeTimestampMillis(safe.suspension.updatedAt),
        }
      : null,
    premium,
  };
}

async function readPremium(uid) {
  const snapshot = await db.collection("premiumEntitlements").doc(uid).get();
  return evaluatePremiumEntitlement(snapshot.exists ? snapshot.data() : null);
}

const getAdminSession = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "dashboard.read");
  await writeAudit(actor, "admin.session.authorized");
  return {
    uid: actor.uid,
    role: actor.role,
    permissions: actor.permissions,
  };
});

const lookupAdminUser = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "users.read");
  const authUser = await resolveAuthUser(request.data && request.data.query);
  const [userSnapshot, premium] = await Promise.all([
    db.collection("users").doc(authUser.uid).get(),
    readPremium(authUser.uid),
  ]);
  const result = publicUserSnapshot(
    authUser.uid,
    userSnapshot.exists ? userSnapshot.data() : null,
    authUser,
    premium,
  );
  await writeAudit(actor, "users.lookup", { targetUid: authUser.uid });
  return result;
});

const setUserSuspension = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "users.suspend");
  const uid = normalizeUid(request.data && request.data.uid);
  const suspended = request.data && request.data.suspended;
  const reason = normalizeReason(request.data && request.data.reason, {
    required: suspended === true,
  });
  if (!uid || typeof suspended !== "boolean" || reason == null) {
    throw new HttpsError("invalid-argument", "Valid uid, suspension state and reason are required.");
  }

  let authUser;
  try {
    authUser = await auth.getUser(uid);
  } catch (error) {
    if (error && error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "User not found.");
    }
    throw error;
  }
  assertTargetIsNotAdmin(authUser);

  const ref = db.collection("users").doc(uid);
  const before = await ref.get();
  if (!before.exists) throw new HttpsError("not-found", "User profile not found.");
  const beforeSuspended = before.data() && before.data().isSuspended === true;

  await ref.set({
    isSuspended: suspended,
    suspension: {
      active: suspended,
      reason: suspended ? reason : "",
      updatedBy: actor.uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  }, { merge: true });

  if (suspended) await auth.revokeRefreshTokens(uid);

  await writeAudit(actor, suspended ? "users.suspend" : "users.unsuspend", {
    targetUid: uid,
    reason,
    beforeSuspended,
    afterSuspended: suspended,
  });
  return { uid, isSuspended: suspended };
});

const getAdminPremiumEntitlement = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "premium.read");
  const authUser = await resolveAuthUser(request.data && request.data.query);
  const entitlement = await readPremium(authUser.uid);
  await writeAudit(actor, "premium.lookup", { targetUid: authUser.uid });
  return {
    uid: authUser.uid,
    email: authUser.email || null,
    entitlement,
  };
});

const setAdminPremiumGrant = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "premium.manage");
  const uid = normalizeUid(request.data && request.data.uid);
  const active = request.data && request.data.active;
  const reason = normalizeReason(request.data && request.data.reason, { required: true });
  const days = active === true ? normalizePremiumDays(request.data && request.data.days) : null;
  if (!uid || typeof active !== "boolean" || reason == null || (active && days == null)) {
    throw new HttpsError(
      "invalid-argument",
      "Valid uid, action reason and approved Premium duration are required.",
    );
  }

  let authUser;
  try {
    authUser = await auth.getUser(uid);
  } catch (error) {
    if (error && error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "User not found.");
    }
    throw error;
  }
  assertTargetIsNotAdmin(authUser);

  const ref = db.collection("premiumEntitlements").doc(uid);
  const now = admin.firestore.Timestamp.now();
  const expiresAt = active
    ? admin.firestore.Timestamp.fromMillis(premiumExpiryMillis(days, now.toMillis()))
    : null;

  let beforeEntitlement;
  let afterEntitlement;
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const current = snapshot.exists ? snapshot.data() || {} : {};
    beforeEntitlement = evaluatePremiumEntitlement(current);
    const currentGrants = current.grants && typeof current.grants === "object"
      ? current.grants
      : {};
    const next = {
      ...current,
      schemaVersion: 1,
      grants: {
        ...currentGrants,
        admin: {
          active,
          expiresAt,
          reason,
          updatedBy: actor.uid,
          updatedAt: now,
        },
      },
      updatedAt: now,
    };
    transaction.set(ref, next, { merge: true });
    afterEntitlement = evaluatePremiumEntitlement(next, now.toMillis());
  });

  await writeAudit(actor, active ? "premium.adminGrant.set" : "premium.adminGrant.revoke", {
    targetUid: uid,
    reason,
    days: active ? days : null,
    before: beforeEntitlement,
    after: afterEntitlement,
  });
  return {
    uid,
    entitlement: afterEntitlement,
  };
});

module.exports = {
  getAdminSession,
  lookupAdminUser,
  setUserSuspension,
  getAdminPremiumEntitlement,
  setAdminPremiumGrant,
};
