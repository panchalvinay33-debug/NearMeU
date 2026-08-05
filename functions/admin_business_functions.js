"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");
const { buildBusinessMetrics } = require("./admin_business_logic");

const REGION = "asia-south1";
const db = admin.firestore();

function requireAdmin(request, permission) {
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

async function countQuery(query) {
  const snapshot = await query.count().get();
  return snapshot.data().count;
}

const getAdminBusinessDashboard = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "business.read");
  const nowMs = Date.now();
  const dayMs = 24 * 60 * 60 * 1000;
  const users = db.collection("users");
  const premium = db.collection("premiumEntitlements");

  const [
    totalUsers,
    onlineUsers,
    suspendedUsers,
    newUsers24h,
    newUsers7d,
    newUsers30d,
    premiumRecords,
    googlePlayMarkedActive,
    adminMarkedActive,
  ] = await Promise.all([
    countQuery(users),
    countQuery(users.where("isOnline", "==", true)),
    countQuery(users.where("isSuspended", "==", true)),
    countQuery(users.where(
      "createdAt",
      ">=",
      admin.firestore.Timestamp.fromMillis(nowMs - dayMs),
    )),
    countQuery(users.where(
      "createdAt",
      ">=",
      admin.firestore.Timestamp.fromMillis(nowMs - 7 * dayMs),
    )),
    countQuery(users.where(
      "createdAt",
      ">=",
      admin.firestore.Timestamp.fromMillis(nowMs - 30 * dayMs),
    )),
    countQuery(premium),
    countQuery(premium.where("grants.googlePlay.active", "==", true)),
    countQuery(premium.where("grants.admin.active", "==", true)),
  ]);

  const metrics = buildBusinessMetrics({
    totalUsers,
    onlineUsers,
    suspendedUsers,
    newUsers24h,
    newUsers7d,
    newUsers30d,
    premiumRecords,
    googlePlayMarkedActive,
    adminMarkedActive,
  });

  const response = {
    generatedAtMillis: nowMs,
    ...metrics,
    notes: {
      privacy: "Aggregate counts only; no chats, exact locations or private profile details are returned.",
      online: "Online count reflects profiles currently marked isOnline=true.",
      premium: "Premium grant counters reflect active flags only; per-user Premium screens remain expiry-aware and authoritative.",
      finance: "Revenue, Play fees and infrastructure costs are not connected to an authoritative finance source yet, so no estimates are shown.",
    },
  };

  await writeAudit(actor, "business.dashboard.read", {
    generatedAtMillis: nowMs,
  });
  return response;
});

module.exports = { getAdminBusinessDashboard };
