"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const db = admin.firestore();
const REGION = "asia-south1";
const CLEANUP_LIMIT = 100;
const RETENTION_MS = 7 * 24 * 60 * 60 * 1000;
const ALLOWED_PRIORITIES = new Set(["normal", "important", "urgent"]);
const ALLOWED_TYPES = new Set([
  "general",
  "new_feature",
  "app_update",
  "maintenance",
  "important",
]);
const ALLOWED_MEDIA = new Set(["image", "video", "voice"]);

function requireUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

async function requireAdmin(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  if (!snapshot.exists || snapshot.get("isAdmin") !== true) {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }
}

function validAnnouncementId(value) {
  return typeof value === "string" && /^[A-Za-z0-9_-]{6,160}$/.test(value);
}

function safeText(value, maximum, fieldName, required = false) {
  const text = typeof value === "string" ? value.trim() : "";
  if ((required && !text) || text.length > maximum) {
    throw new HttpsError("invalid-argument", `${fieldName} is invalid.`);
  }
  return text || null;
}

function normalizeMedia(value, announcementId) {
  if (value == null) return null;
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "Media metadata is invalid.");
  }
  const type = value.type;
  const storagePath = value.storagePath;
  const contentType = value.contentType;
  const sizeBytes = value.sizeBytes;
  const durationMs = value.durationMs;
  if (
    !ALLOWED_MEDIA.has(type) ||
    typeof storagePath !== "string" ||
    !storagePath.startsWith(`announcementMedia/${announcementId}/`) ||
    typeof contentType !== "string" ||
    !Number.isInteger(sizeBytes) ||
    sizeBytes <= 0
  ) {
    throw new HttpsError("invalid-argument", "Media metadata is invalid.");
  }
  const limits = { image: 5 * 1024 * 1024, video: 30 * 1024 * 1024, voice: 8 * 1024 * 1024 };
  if (sizeBytes > limits[type]) {
    throw new HttpsError("invalid-argument", "Announcement media is too large.");
  }
  if ((type === "video" || type === "voice") &&
      (!Number.isInteger(durationMs) || durationMs <= 0 || durationMs > 120000)) {
    throw new HttpsError("invalid-argument", "Announcement media duration is invalid.");
  }
  return { type, storagePath, contentType, sizeBytes, durationMs: durationMs || null };
}

async function deleteStorageObject(path) {
  if (typeof path !== "string" || !path.startsWith("announcementMedia/")) return;
  await admin.storage().bucket().file(path).delete({ ignoreNotFound: true });
}

async function expireAnnouncementDocument(document, reason) {
  const data = document.data() || {};
  await deleteStorageObject(data.mediaStoragePath);
  await document.ref.set(
    {
      isActive: false,
      expiresAt: admin.firestore.FieldValue.serverTimestamp(),
      mediaDeletedAt: data.mediaStoragePath
        ? admin.firestore.FieldValue.serverTimestamp()
        : data.mediaDeletedAt || null,
      mediaDeleteReason: reason,
    },
    { merge: true },
  );
}

exports.createSupportAnnouncement = onCall(
  { region: REGION, timeoutSeconds: 120, memory: "256MiB" },
  async (request) => {
    const uid = requireUid(request);
    await requireAdmin(uid);
    const data = request.data || {};
    const announcementId = data.announcementId;
    if (!validAnnouncementId(announcementId)) {
      throw new HttpsError("invalid-argument", "Announcement ID is invalid.");
    }
    const title = safeText(data.title, 80, "Title", true);
    const message = safeText(data.message, 1000, "Message", true);
    const priority = data.priority;
    const announcementType = data.announcementType;
    if (!ALLOWED_PRIORITIES.has(priority) || !ALLOWED_TYPES.has(announcementType)) {
      throw new HttpsError("invalid-argument", "Announcement settings are invalid.");
    }
    const media = normalizeMedia(data.media, announcementId);
    const updateVersion = safeText(data.updateVersion, 40, "Version");
    const updateUrl = safeText(data.updateUrl, 2048, "Update URL");
    const updateButtonLabel = safeText(data.updateButtonLabel, 40, "Button label");
    if (announcementType === "app_update" && !updateUrl) {
      throw new HttpsError("invalid-argument", "An update URL is required.");
    }

    const now = admin.firestore.Timestamp.now();
    const reference = db.collection("supportAnnouncements").doc(announcementId);
    if ((await reference.get()).exists) {
      throw new HttpsError("already-exists", "Announcement already exists.");
    }
    await reference.set({
      title,
      message,
      priority,
      type: "official_announcement",
      announcementType,
      targetAudience: "allActiveUsers",
      isActive: true,
      createdByAdminId: uid,
      createdAt: now,
      expiresAt: null,
      mediaType: media && media.type,
      mediaStoragePath: media && media.storagePath,
      mediaContentType: media && media.contentType,
      mediaSizeBytes: media && media.sizeBytes,
      mediaDurationMs: media && media.durationMs,
      mediaExpiresAt: media
        ? admin.firestore.Timestamp.fromMillis(now.toMillis() + RETENTION_MS)
        : null,
      mediaDeletedAt: null,
      updateVersion,
      updateUrl,
      updateButtonLabel: updateButtonLabel ||
        (announcementType === "app_update" ? "Update now" : null),
      isMandatoryUpdate: announcementType === "app_update" && data.isMandatoryUpdate === true,
    });
    return { success: true, announcementId };
  },
);

exports.expireSupportAnnouncement = onCall(
  { region: REGION, timeoutSeconds: 120, memory: "256MiB" },
  async (request) => {
    const uid = requireUid(request);
    await requireAdmin(uid);
    const announcementId = request.data && request.data.announcementId;
    if (!validAnnouncementId(announcementId)) {
      throw new HttpsError("invalid-argument", "Announcement ID is invalid.");
    }

    const reference = db.collection("supportAnnouncements").doc(announcementId);
    const snapshot = await reference.get();
    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Announcement was not found.");
    }
    await expireAnnouncementDocument(snapshot, "admin_expired");
    return { success: true };
  },
);

exports.purgeExpiredAnnouncementMedia = onSchedule(
  {
    schedule: "every 6 hours",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "256MiB",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await db
      .collection("supportAnnouncements")
      .where("mediaExpiresAt", "<=", now)
      .limit(CLEANUP_LIMIT)
      .get();

    let cleaned = 0;
    for (const document of snapshot.docs) {
      const data = document.data() || {};
      if (!data.mediaStoragePath || data.mediaDeletedAt) continue;
      try {
        await deleteStorageObject(data.mediaStoragePath);
        await document.ref.set(
          {
            mediaDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
            mediaDeleteReason: "seven_day_retention",
          },
          { merge: true },
        );
        cleaned += 1;
      } catch (error) {
        logger.error("Announcement media cleanup failed", {
          announcementId: document.id,
          storagePath: data.mediaStoragePath,
          error,
        });
      }
    }
    logger.info("Announcement media retention cleanup complete", { cleaned });
  },
);
