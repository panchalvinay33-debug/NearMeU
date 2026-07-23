"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const {
  buildChatNotification,
  invalidTokenIndexes,
  sanitizePlatform,
  tokenDocumentId,
} = require("./notification_logic");
const { isRecentAuthentication } = require("./account_deletion_logic");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const REGION = "asia-south1";
const MAX_TOKEN_LENGTH = 4096;
const MULTICAST_LIMIT = 500;
const DELETE_BATCH_LIMIT = 400;
const DELETION_JOB_LIMIT = 20;

function appCheckedCall(options, handler) {
  return onCall(
    {
      region: REGION,
      enforceAppCheck: true,
      ...options,
    },
    handler,
  );
}

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  return uid;
}

function requireRecentAuthentication(request) {
  const uid = requireAuthenticatedUid(request);
  if (!isRecentAuthentication(request.auth)) {
    throw new HttpsError(
      "failed-precondition",
      "Please sign in again before deleting your account.",
    );
  }
  return uid;
}

function validatedToken(data) {
  const token = data && typeof data.token === "string" ? data.token.trim() : "";
  if (!token || token.length > MAX_TOKEN_LENGTH) {
    throw new HttpsError("invalid-argument", "A valid device token is required.");
  }
  return token;
}

function deletionJobRef(uid) {
  return db.collection("accountDeletionJobs").doc(uid);
}

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

async function deleteAllDeviceTokensForUid(uid) {
  const devicesRef = db
    .collection("privateProfiles")
    .doc(uid)
    .collection("devices");
  let deletedCount = 0;

  while (true) {
    const devices = await devicesRef.limit(DELETE_BATCH_LIMIT).get();
    if (devices.empty) break;

    await db.runTransaction(async (transaction) => {
      const ownerRefs = devices.docs.map((device) =>
        db.collection("deviceTokenOwners").doc(device.id),
      );
      const ownerSnapshots = await Promise.all(
        ownerRefs.map((ownerRef) => transaction.get(ownerRef)),
      );

      devices.docs.forEach((device, index) => {
        transaction.delete(device.ref);
        const ownerSnapshot = ownerSnapshots[index];
        if (ownerSnapshot.exists && ownerSnapshot.get("ownerId") === uid) {
          transaction.delete(ownerRefs[index]);
        }
      });
    });

    deletedCount += devices.size;
  }

  deletedCount += await deleteQueryDocuments(
    db.collection("deviceTokenOwners").where("ownerId", "==", uid),
  );
  return deletedCount;
}

async function hideMessagesForDeletedUser(chatRef, uid) {
  let hiddenCount = 0;
  let cursor = null;

  while (true) {
    let query = chatRef
      .collection("messages")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(DELETE_BATCH_LIMIT);
    if (cursor) query = query.startAfter(cursor);

    const messages = await query.get();
    if (messages.empty) break;

    const batch = db.batch();
    let writeCount = 0;
    for (const message of messages.docs) {
      const deletedFor = message.get("deletedFor");
      if (Array.isArray(deletedFor) && deletedFor.includes(uid)) continue;
      batch.update(message.ref, {
        deletedFor: admin.firestore.FieldValue.arrayUnion(uid),
      });
      writeCount += 1;
    }

    if (writeCount > 0) {
      await batch.commit();
      hiddenCount += writeCount;
    }
    cursor = messages.docs[messages.docs.length - 1];
  }

  return hiddenCount;
}

async function hideAllChatsForDeletedUser(uid) {
  const chats = await db
    .collection("chats")
    .where("participants", "array-contains", uid)
    .get();
  let hiddenMessageCount = 0;

  for (const chat of chats.docs) {
    hiddenMessageCount += await hideMessagesForDeletedUser(chat.ref, uid);
  }

  return {
    chatCount: chats.size,
    hiddenMessageCount,
  };
}

async function deleteAccountFirestoreData(uid) {
  const chatCleanup = await hideAllChatsForDeletedUser(uid);
  const deviceCount = await deleteAllDeviceTokensForUid(uid);
  const ownBlockCount = await deleteQueryDocuments(
    db.collection("users").doc(uid).collection("blocks"),
  );
  const incomingBlockCount = await deleteQueryDocuments(
    db.collectionGroup("blocks").where("blockedUserId", "==", uid),
  );
  const reportsByUserCount = await deleteQueryDocuments(
    db.collection("reports").where("reporterId", "==", uid),
  );
  const reportsAboutUserCount = await deleteQueryDocuments(
    db.collection("reports").where("reportedUserId", "==", uid),
  );

  const finalBatch = db.batch();
  finalBatch.delete(db.collection("privateProfiles").doc(uid));
  finalBatch.delete(db.collection("users").doc(uid));
  await finalBatch.commit();

  return {
    ...chatCleanup,
    deviceCount,
    ownBlockCount,
    incomingBlockCount,
    reportsByUserCount,
    reportsAboutUserCount,
  };
}

async function completeAccountDeletionJob(uid) {
  const cleanup = await deleteAccountFirestoreData(uid);
  await deletionJobRef(uid).delete();
  logger.info("Account data cleanup completed", { uid, ...cleanup });
  return cleanup;
}

exports.registerDeviceToken = appCheckedCall({}, async (request) => {
  const uid = requireAuthenticatedUid(request);
  const token = validatedToken(request.data);
  const platform = sanitizePlatform(request.data && request.data.platform);
  const tokenId = tokenDocumentId(token);
  const ownerRef = db.collection("deviceTokenOwners").doc(tokenId);
  const deviceRef = db
    .collection("privateProfiles")
    .doc(uid)
    .collection("devices")
    .doc(tokenId);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (transaction) => {
    const [userSnapshot, ownerSnapshot] = await Promise.all([
      transaction.get(userRef),
      transaction.get(ownerRef),
    ]);

    if (!userSnapshot.exists || userSnapshot.get("isSuspended") === true) {
      throw new HttpsError(
        "failed-precondition",
        "An active NearMeU profile is required.",
      );
    }

    const previousUid = ownerSnapshot.exists
      ? ownerSnapshot.get("ownerId")
      : null;
    if (previousUid && previousUid !== uid) {
      transaction.delete(
        db
          .collection("privateProfiles")
          .doc(previousUid)
          .collection("devices")
          .doc(tokenId),
      );
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    transaction.set(deviceRef, {
      ownerId: uid,
      token,
      platform,
      updatedAt: now,
    });
    transaction.set(ownerRef, {
      ownerId: uid,
      updatedAt: now,
    });
  });

  return { success: true };
});

exports.unregisterDeviceToken = appCheckedCall({}, async (request) => {
  const uid = requireAuthenticatedUid(request);
  const token = validatedToken(request.data);
  const tokenId = tokenDocumentId(token);
  const ownerRef = db.collection("deviceTokenOwners").doc(tokenId);
  const deviceRef = db
    .collection("privateProfiles")
    .doc(uid)
    .collection("devices")
    .doc(tokenId);

  await db.runTransaction(async (transaction) => {
    const ownerSnapshot = await transaction.get(ownerRef);
    transaction.delete(deviceRef);
    if (ownerSnapshot.exists && ownerSnapshot.get("ownerId") === uid) {
      transaction.delete(ownerRef);
    }
  });

  return { success: true };
});

exports.unregisterAllDeviceTokens = appCheckedCall(
  {},
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    const deletedCount = await deleteAllDeviceTokensForUid(uid);
    return { success: true, deletedCount };
  },
);

exports.deleteCurrentAccount = appCheckedCall(
  { timeoutSeconds: 540, memory: "512MiB" },
  async (request) => {
    const uid = requireRecentAuthentication(request);
    const jobRef = deletionJobRef(uid);
    const now = admin.firestore.FieldValue.serverTimestamp();

    await jobRef.set(
      {
        uid,
        status: "pending",
        requestedAt: now,
        updatedAt: now,
        attempts: admin.firestore.FieldValue.increment(1),
      },
      { merge: true },
    );

    try {
      await admin.auth().deleteUser(uid);
    } catch (error) {
      if (!error || error.code !== "auth/user-not-found") {
        await jobRef.delete();
        throw error;
      }
    }

    try {
      const cleanup = await completeAccountDeletionJob(uid);
      return { success: true, cleanupPending: false, ...cleanup };
    } catch (error) {
      logger.error("Account cleanup deferred for scheduled retry", {
        uid,
        error,
      });
      await jobRef.set(
        {
          status: "retryPending",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastError: String(error && error.message ? error.message : error).slice(
            0,
            500,
          ),
        },
        { merge: true },
      );
      return { success: true, cleanupPending: true };
    }
  },
);

exports.retryPendingAccountDeletions = onSchedule(
  {
    schedule: "every 30 minutes",
    region: REGION,
    timeZone: "UTC",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const jobs = await db
      .collection("accountDeletionJobs")
      .orderBy("requestedAt", "asc")
      .limit(DELETION_JOB_LIMIT)
      .get();

    for (const job of jobs.docs) {
      try {
        await completeAccountDeletionJob(job.id);
      } catch (error) {
        logger.error("Scheduled account cleanup failed", {
          uid: job.id,
          error,
        });
        await job.ref.set(
          {
            status: "retryPending",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            attempts: admin.firestore.FieldValue.increment(1),
            lastError: String(
              error && error.message ? error.message : error,
            ).slice(0, 500),
          },
          { merge: true },
        );
      }
    }
  },
);

exports.sendPrivateChatNotification = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: REGION,
    retry: false,
  },
  async (event) => {
    const messageSnapshot = event.data;
    if (!messageSnapshot) return;

    const message = messageSnapshot.data();
    const senderId = typeof message.senderId === "string" ? message.senderId : "";
    const receiverId =
      typeof message.receiverId === "string" ? message.receiverId : "";
    if (!senderId || !receiverId || senderId === receiverId) return;

    const receiverRef = db.collection("users").doc(receiverId);
    const senderRef = db.collection("users").doc(senderId);
    const receiverPrivateRef = db.collection("privateProfiles").doc(receiverId);
    const blockedByReceiverRef = receiverRef.collection("blocks").doc(senderId);
    const blockedBySenderRef = senderRef.collection("blocks").doc(receiverId);

    const [
      receiverSnapshot,
      receiverPrivateSnapshot,
      blockedByReceiver,
      blockedBySender,
    ] = await db.getAll(
      receiverRef,
      receiverPrivateRef,
      blockedByReceiverRef,
      blockedBySenderRef,
    );

    if (
      !receiverSnapshot.exists ||
      receiverSnapshot.get("isSuspended") === true ||
      blockedByReceiver.exists ||
      blockedBySender.exists
    ) {
      return;
    }

    if (
      receiverPrivateSnapshot.exists &&
      receiverPrivateSnapshot.get("messageNotificationsEnabled") === false
    ) {
      return;
    }

    const devices = await receiverPrivateRef
      .collection("devices")
      .orderBy("updatedAt", "desc")
      .limit(500)
      .get();
    if (devices.empty) return;

    const uniqueDevices = [];
    const seenTokens = new Set();
    for (const device of devices.docs) {
      const token = device.get("token");
      if (typeof token !== "string" || !token || seenTokens.has(token)) continue;
      seenTokens.add(token);
      uniqueDevices.push({ snapshot: device, token });
    }
    if (!uniqueDevices.length) return;

    const basePayload = buildChatNotification({
      chatId: event.params.chatId,
    });

    for (let start = 0; start < uniqueDevices.length; start += MULTICAST_LIMIT) {
      const chunk = uniqueDevices.slice(start, start + MULTICAST_LIMIT);
      const response = await messaging.sendEachForMulticast({
        ...basePayload,
        tokens: chunk.map((item) => item.token),
      });

      const invalidIndexes = invalidTokenIndexes(response.responses);
      if (!invalidIndexes.length) continue;

      const batch = db.batch();
      for (const index of invalidIndexes) {
        const invalidDevice = chunk[index];
        if (!invalidDevice) continue;
        batch.delete(invalidDevice.snapshot.ref);
        batch.delete(
          db
            .collection("deviceTokenOwners")
            .doc(tokenDocumentId(invalidDevice.token)),
        );
      }
      await batch.commit();
    }

    logger.info("Private chat push processed", {
      chatId: event.params.chatId,
      receiverId,
      deviceCount: uniqueDevices.length,
    });
  },
);
