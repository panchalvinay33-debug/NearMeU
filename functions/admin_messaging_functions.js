"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");
const { buildMessagingHealthMetrics } = require("./admin_messaging_logic");

const REGION = "asia-south1";
const WINDOW_HOURS = 24;
const SAMPLE_LIMIT = 1000;
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

const getAdminMessagingHealth = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "messaging.readHealth");
  const generatedAtMillis = Date.now();
  const cutoffMillis = generatedAtMillis - WINDOW_HOURS * 60 * 60 * 1000;
  const cutoff = admin.firestore.Timestamp.fromMillis(cutoffMillis);

  // Privacy boundary: read only operational metadata needed for aggregate
  // health. Do not fetch text, reply content, sender/receiver IDs, media URL,
  // storage path, chat IDs, exact location, or private profile fields.
  const snapshot = await db
    .collectionGroup("messages")
    .where("timestamp", ">=", cutoff)
    .select(
      "timestamp",
      "type",
      "isDelivered",
      "isSeen",
      "isUnsent",
      "mediaSizeBytes",
      "mediaDurationMs",
      "cloudMediaDeletePending",
    )
    .limit(SAMPLE_LIMIT)
    .get();

  const rows = snapshot.docs.map((doc) => doc.data());
  const metrics = buildMessagingHealthMetrics(rows);
  const response = {
    generatedAtMillis,
    windowHours: WINDOW_HOURS,
    sampleLimit: SAMPLE_LIMIT,
    sampleCapped: snapshot.size >= SAMPLE_LIMIT,
    ...metrics,
    boundaries: {
      contentBrowser: false,
      messageTextIncluded: false,
      senderReceiverIdsIncluded: false,
      mediaUrlsIncluded: false,
      mediaPathsIncluded: false,
      exactLocationIncluded: false,
      callRecordingsIncluded: false,
    },
    notes: {
      scope: "Recent aggregate messaging delivery/media/voice-message health only.",
      sample: "Metrics use a bounded recent metadata sample and are not billing or finance truth.",
      privacy: "No message text, identities, chat browser, media URLs/storage paths or exact location are returned.",
      calling: "Voice messages are included; live voice/video call health remains a separate calling batch.",
    },
  };

  await writeAudit(actor, "messaging.health.read", {
    generatedAtMillis,
    windowHours: WINDOW_HOURS,
    sampledMessages: metrics.sampledMessages,
    sampleCapped: response.sampleCapped,
  });
  return response;
});

module.exports = { getAdminMessagingHealth };
