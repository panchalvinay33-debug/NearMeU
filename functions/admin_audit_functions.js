"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");
const { normalizeAuditLimit, projectAuditEvent } = require("./admin_audit_logic");

const REGION = "asia-south1";
const db = admin.firestore();

function requireAdmin(request, permission) {
  const result = evaluateAdminAuthorization(request.auth, permission);
  if (!result.ok) {
    throw new HttpsError(
      result.code,
      result.code === "unauthenticated" ? "Authentication required." : "Admin authorization required.",
    );
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

const listAdminAuditEvents = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "audit.read");
  const limit = normalizeAuditLimit(request.data && request.data.limit);
  const snapshot = await db
    .collection("adminAudit")
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  const events = snapshot.docs.map((doc) => projectAuditEvent(doc.id, doc.data()));
  const generatedAtMillis = Date.now();

  await writeAudit(actor, "audit.read", {
    generatedAtMillis,
    count: events.length,
  });

  return {
    generatedAtMillis,
    limit,
    events,
    boundaries: {
      rawDetailsIncluded: false,
      consumerEmailIncluded: false,
      messageContentIncluded: false,
      mediaPathsIncluded: false,
      exactLocationIncluded: false,
      secretsIncluded: false,
    },
  };
});

module.exports = { listAdminAuditEvents };