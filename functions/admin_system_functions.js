"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");
const { buildSystemHealth } = require("./admin_system_logic");

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

async function safeCheck(task, okDetail) {
  try {
    const value = await task();
    return { status: "ok", detail: okDetail(value), authoritative: true };
  } catch (error) {
    return {
      status: "error",
      detail: error && error.code ? String(error.code) : "check-failed",
      authoritative: true,
    };
  }
}

const getAdminSystemHealth = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "system.read");
  const generatedAtMillis = Date.now();

  const firestorePromise = safeCheck(
    () => db.collection("appConfig").doc("android").get(),
    () => "Firestore read succeeded.",
  );
  const releasePromise = safeCheck(
    () => db.collection("appConfig").doc("android").get(),
    (snapshot) => {
      if (!snapshot.exists) return "No Android release policy document is configured.";
      const data = snapshot.data() || {};
      const latest = Number.isInteger(data.latestVersionCode) ? data.latestVersionCode : null;
      const minimum = Number.isInteger(data.minimumSupportedVersionCode)
        ? data.minimumSupportedVersionCode
        : null;
      const maintenance = data.maintenanceMode === true;
      return `latest=${latest ?? "unknown"}, minimum=${minimum ?? "unknown"}, maintenance=${maintenance}`;
    },
  );
  const premiumPromise = safeCheck(
    () => db.collection("premiumEntitlements").limit(1).get(),
    () => "Premium entitlement store is readable.",
  );
  const recoveryPromise = safeCheck(
    () => db.collection("premiumRecoveryUsers").limit(1).get(),
    () => "Premium recovery store is readable.",
  );
  const storagePromise = safeCheck(
    () => admin.storage().bucket().getMetadata(),
    (metadata) => `Storage bucket metadata readable (${metadata && metadata[0] && metadata[0].name ? metadata[0].name : "configured bucket"}).`,
  );

  const [firestore, release, premium, recovery, storage] = await Promise.all([
    firestorePromise,
    releasePromise,
    premiumPromise,
    recoveryPromise,
    storagePromise,
  ]);

  const health = buildSystemHealth({
    firestore,
    auth: {
      status: request.auth && request.auth.uid ? "ok" : "error",
      detail: "Authenticated callable request verified by Firebase Auth.",
      authoritative: true,
    },
    storage,
    functions: {
      status: "ok",
      detail: `getAdminSystemHealth is executing in ${REGION}.`,
      authoritative: true,
    },
    release,
    premium,
    recovery,
    crashlytics: {
      status: "unavailable",
      detail: "Crashlytics aggregate telemetry is not integrated into this Admin backend yet.",
      authoritative: false,
    },
  });

  const response = {
    generatedAtMillis,
    region: REGION,
    ...health,
    boundaries: {
      secretsIncluded: false,
      userPrivateDataIncluded: false,
      crashReportsIncluded: false,
      messageContentIncluded: false,
      exactLocationIncluded: false,
    },
    notes: {
      semantics: "OK means the specific authoritative probe succeeded at snapshot time; it is not an uptime SLA.",
      crashlytics: "Crash telemetry is explicitly unavailable until an authoritative aggregate integration is accepted.",
      privacy: "System Health returns infrastructure/release status only and no private user content.",
    },
  };

  await writeAudit(actor, "system.health.read", {
    generatedAtMillis,
    overallStatus: response.overallStatus,
    verifiedChecks: response.verifiedChecks,
    unavailableChecks: response.unavailableChecks,
  });
  return response;
});

module.exports = { getAdminSystemHealth };
