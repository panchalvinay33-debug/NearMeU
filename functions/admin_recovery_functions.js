"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");
const { RETENTION_DAYS, RETENTION_POLICY_VERSION } = require("./message_retention_logic");
const { RECOVERY_MONTHS, RECOVERY_POLICY_VERSION } = require("./premium_recovery_logic");
const { buildRecoveryHealthMetrics } = require("./admin_recovery_logic");

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

const getAdminRecoveryHealth = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "recovery.read");
  const nowMs = Date.now();
  const dayMs = 24 * 60 * 60 * 1000;
  const now = admin.firestore.Timestamp.fromMillis(nowMs);
  const next24h = admin.firestore.Timestamp.fromMillis(nowMs + dayMs);
  const next7d = admin.firestore.Timestamp.fromMillis(nowMs + 7 * dayMs);
  const messages = db.collectionGroup("messages");

  const [
    deliveryActive,
    deliveryExpiredBacklog,
    deliveryExpiring24h,
    premiumRecoveryUsers,
    premiumRecoveryActive,
    premiumRecoveryExpiredBacklog,
    premiumRecoveryExpiring7d,
  ] = await Promise.all([
    countQuery(messages.where("cloudExpiresAt", ">", now)),
    countQuery(messages.where("cloudExpiresAt", "<=", now)),
    countQuery(messages
      .where("cloudExpiresAt", ">", now)
      .where("cloudExpiresAt", "<=", next24h)),
    countQuery(db.collection("premiumRecoveryUsers")),
    countQuery(messages.where("recoveryExpiresAt", ">", now)),
    countQuery(messages.where("recoveryExpiresAt", "<=", now)),
    countQuery(messages
      .where("recoveryExpiresAt", ">", now)
      .where("recoveryExpiresAt", "<=", next7d)),
  ]);

  const metrics = buildRecoveryHealthMetrics({
    deliveryActive,
    deliveryExpiredBacklog,
    deliveryExpiring24h,
    premiumRecoveryUsers,
    premiumRecoveryActive,
    premiumRecoveryExpiredBacklog,
    premiumRecoveryExpiring7d,
  });

  const response = {
    generatedAtMillis: nowMs,
    policies: {
      deliveryRetentionDays: RETENTION_DAYS,
      deliveryPolicyVersion: RETENTION_POLICY_VERSION,
      premiumRecoveryMonths: RECOVERY_MONTHS,
      premiumRecoveryPolicyVersion: RECOVERY_POLICY_VERSION,
    },
    ...metrics,
    boundaries: {
      contentBrowser: false,
      messageTextIncluded: false,
      mediaPathsIncluded: false,
      userRecoveryLookup: false,
      exactLocationIncluded: false,
    },
    notes: {
      delivery: "Temporary delivery-cloud health only. Expired backlog is expected to be drained by the hourly retention purge.",
      premiumRecovery: "Premium recovery health only. Eligible recovery is retained per recorded expiry and Clear Chat/permanent deletion rules remain authoritative.",
      privacy: "Aggregate counters only; no recovery content, chat text, media paths, exact location or per-user recovery browser is returned.",
    },
  };

  await writeAudit(actor, "recovery.health.read", {
    generatedAtMillis: nowMs,
  });
  return response;
});

module.exports = { getAdminRecoveryHealth };
