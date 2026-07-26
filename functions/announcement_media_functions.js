"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const db = admin.firestore();
const REGION = "asia-south1";
const CLEANUP_LIMIT = 100;

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
