"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");

const REGION = "asia-south1";
const db = admin.firestore();

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

const getAdminSession = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "dashboard.read");
  await writeAudit(actor, "admin.session.authorized");
  return {
    uid: actor.uid,
    role: actor.role,
    permissions: actor.permissions,
  };
});

module.exports = { getAdminSession };
