"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");

const { storageObjectPathFromUrl } = require("./deletion_cleanup_logic");

const db = admin.firestore();
const REGION = "asia-south1";
const DELETE_BATCH_LIMIT = 400;

async function deleteQueryDocuments(query) {
  let deletedCount = 0;

  while (true) {
    const snapshot = await query.limit(DELETE_BATCH_LIMIT).get();
    if (snapshot.empty) break;

    const batch = db.batch();
    for (const document of snapshot.docs) {
      batch.delete(document.ref);
    }
    await batch.commit();
    deletedCount += snapshot.size;
  }

  return deletedCount;
}

async function deleteProfilePhoto(photoUrl) {
  const objectPath = storageObjectPathFromUrl(photoUrl);
  if (!objectPath) return false;

  await admin.storage().bucket().file(objectPath).delete({ ignoreNotFound: true });
  return true;
}

exports.cleanupDeletedUserSafetyData = onDocumentDeleted(
  {
    document: "users/{uid}",
    region: REGION,
    retry: true,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (event) => {
    const uid = event.params.uid;
    const deletedProfile = event.data && event.data.data ? event.data.data() : {};

    await db.collection("antiAbuseUsers").doc(uid).delete();

    const reportLocksAsReporter = await deleteQueryDocuments(
      db.collection("reportLocks").where("reporterId", "==", uid),
    );
    const reportLocksAsTarget = await deleteQueryDocuments(
      db.collection("reportLocks").where("reportedUserId", "==", uid),
    );
    const auditLogsAsActor = await deleteQueryDocuments(
      db.collection("moderationAuditLogs").where("actorId", "==", uid),
    );
    const auditLogsAsTarget = await deleteQueryDocuments(
      db.collection("moderationAuditLogs").where("targetUserId", "==", uid),
    );

    let profilePhotoDeleted = false;
    try {
      profilePhotoDeleted = await deleteProfilePhoto(deletedProfile.photoUrl);
    } catch (error) {
      logger.error("Unable to delete profile photo after account deletion", {
        uid,
        error,
      });
      throw error;
    }

    logger.info("Deleted user-linked safety data", {
      uid,
      reportLocksAsReporter,
      reportLocksAsTarget,
      auditLogsAsActor,
      auditLogsAsTarget,
      profilePhotoDeleted,
    });
  },
);
