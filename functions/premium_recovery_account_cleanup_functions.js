"use strict";

const admin = require("firebase-admin");
const functionsV1 = require("firebase-functions/v1");
const { logger } = require("firebase-functions");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const REGION = "asia-south1";
const JOB_LIMIT = 20;
const MESSAGE_BATCH_LIMIT = 400;

const db = admin.firestore();

function recoveryRootRef(uid) {
  return db.collection("premiumRecoveryUsers").doc(uid);
}

function cleanupJobRef(uid) {
  return db.collection("premiumRecoveryDeletionJobs").doc(uid);
}

async function deleteRecoveryFirestore(uid) {
  const root = recoveryRootRef(uid);
  const chatRefs = await root.collection("chats").listDocuments();

  for (const chatRef of chatRefs) {
    while (true) {
      const messages = await chatRef
        .collection("messages")
        .limit(MESSAGE_BATCH_LIMIT)
        .get();
      if (messages.empty) break;
      const batch = db.batch();
      for (const message of messages.docs) batch.delete(message.ref);
      await batch.commit();
    }
    await chatRef.delete().catch(() => {});
  }

  await root.delete().catch(() => {});
}

async function purgeRecoveryForDeletedUid(uid) {
  if (typeof uid !== "string" || !uid) return;

  // Recovery media is a dedicated owner-scoped prefix, so permanent account
  // deletion can remove the whole prefix without touching another user's copy.
  await admin.storage().bucket().deleteFiles({
    prefix: `premiumRecoveryMedia/${uid}/`,
    force: true,
  });
  await deleteRecoveryFirestore(uid);
  await cleanupJobRef(uid).delete().catch(() => {});
}

async function enqueueAndRun(uid) {
  const jobRef = cleanupJobRef(uid);
  await jobRef.set(
    {
      uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      attempts: admin.firestore.FieldValue.increment(1),
    },
    { merge: true },
  );
  await purgeRecoveryForDeletedUid(uid);
}

exports.purgePremiumRecoveryOnAuthDelete = functionsV1
  .region(REGION)
  .auth.user()
  .onDelete(async (user) => {
    try {
      await enqueueAndRun(user.uid);
    } catch (error) {
      logger.error("Permanent-account Premium recovery cleanup deferred", {
        uid: user.uid,
        error,
      });
      // The durable job survives so the scheduler can retry even if this
      // background invocation itself is not retried by the platform.
    }
  });

exports.retryPremiumRecoveryAccountDeletion = onSchedule(
  {
    schedule: "every 60 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const jobs = await db
      .collection("premiumRecoveryDeletionJobs")
      .limit(JOB_LIMIT)
      .get();
    if (jobs.empty) return;

    let completed = 0;
    for (const job of jobs.docs) {
      const uid = job.get("uid") || job.id;
      try {
        await enqueueAndRun(uid);
        completed += 1;
      } catch (error) {
        logger.error("Premium recovery account-deletion retry failed", {
          uid,
          error,
        });
      }
    }
    logger.info("Premium recovery account-deletion retry pass complete", {
      queried: jobs.size,
      completed,
    });
  },
);
