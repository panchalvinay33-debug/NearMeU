const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;

function approximateCoordinate(value) {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return Math.round(value * 10) / 10;
}

function publicProfileFromPrivate(uid, user) {
  const suspended = user.isSuspended === true;
  return {
    uid,
    nickname: typeof user.nickname === "string" ? user.nickname.trim() : "",
    gender: typeof user.gender === "string" ? user.gender : "",
    lookingFor: typeof user.lookingFor === "string" ? user.lookingFor : "",
    age: Number.isInteger(user.age) ? user.age : null,
    state: typeof user.state === "string" ? user.state.trim() : null,
    photoUrl:
      typeof user.photoUrl === "string" && user.photoUrl.trim().length > 0
        ? user.photoUrl.trim()
        : null,
    approxLatitude: approximateCoordinate(user.latitude),
    approxLongitude: approximateCoordinate(user.longitude),
    createdAt: user.createdAt || serverTimestamp(),
    lastSeen: user.lastSeen || null,
    isOnline: suspended ? false : user.isOnline === true,
    isSuspended: suspended,
    updatedAt: serverTimestamp(),
  };
}

async function assertAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }

  const adminSnapshot = await db
    .collection("users")
    .doc(request.auth.uid)
    .get();
  if (!adminSnapshot.exists || adminSnapshot.get("isAdmin") !== true) {
    throw new HttpsError("permission-denied", "Admin permission required.");
  }
}

function assertRecentLogin(request, maxAgeSeconds = 600) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }

  const authTime = Number(request.auth.token.auth_time);
  const nowSeconds = Math.floor(Date.now() / 1000);
  if (!Number.isFinite(authTime) || nowSeconds - authTime > maxAgeSeconds) {
    throw new HttpsError(
      "failed-precondition",
      "Please sign in again before deleting your account.",
      { reason: "RECENT_LOGIN_REQUIRED" },
    );
  }
}

async function deleteQueryRecursively(query, pageSize = 50) {
  let deleted = 0;
  while (true) {
    const snapshot = await query.limit(pageSize).get();
    if (snapshot.empty) return deleted;
    for (const document of snapshot.docs) {
      await db.recursiveDelete(document.ref);
      deleted += 1;
    }
  }
}

async function deleteQueryDocuments(query, pageSize = 400) {
  let deleted = 0;
  while (true) {
    const snapshot = await query.limit(pageSize).get();
    if (snapshot.empty) return deleted;
    const batch = db.batch();
    snapshot.docs.forEach((document) => batch.delete(document.ref));
    await batch.commit();
    deleted += snapshot.size;
  }
}

async function anonymizeReports(uid, field, updates) {
  let updated = 0;
  while (true) {
    const snapshot = await db
      .collection("reports")
      .where(field, "==", uid)
      .limit(400)
      .get();
    if (snapshot.empty) return updated;

    const batch = db.batch();
    snapshot.docs.forEach((document) => batch.update(document.ref, updates));
    await batch.commit();
    updated += snapshot.size;

    if (snapshot.size < 400) return updated;
  }
}

exports.syncPublicProfile = onDocumentWritten(
  {
    document: "users/{userId}",
    region: "asia-south1",
    retry: true,
  },
  async (event) => {
    const publicRef = db.collection("publicProfiles").doc(event.params.userId);
    const after = event.data && event.data.after;

    if (!after || !after.exists) {
      await publicRef.delete();
      return;
    }

    const data = after.data() || {};
    const profile = publicProfileFromPrivate(event.params.userId, data);
    if (
      !profile.nickname ||
      !Number.isInteger(profile.age) ||
      profile.age < 18 ||
      profile.age > 99 ||
      !["Male", "Female", "Other"].includes(profile.gender) ||
      !["Male", "Female", "Both"].includes(profile.lookingFor)
    ) {
      await publicRef.delete();
      return;
    }

    await publicRef.set(profile, { merge: false });
  },
);

exports.backfillPublicProfiles = onCall(
  {
    region: "asia-south1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (request) => {
    await assertAdmin(request);

    const usersSnapshot = await db.collection("users").get();
    const writer = db.bulkWriter();
    let publicProfilesWritten = 0;
    let blockEdgesWritten = 0;

    for (const userSnapshot of usersSnapshot.docs) {
      const uid = userSnapshot.id;
      const user = userSnapshot.data() || {};
      const profile = publicProfileFromPrivate(uid, user);
      if (
        profile.nickname &&
        Number.isInteger(profile.age) &&
        profile.age >= 18 &&
        profile.age <= 99 &&
        ["Male", "Female", "Other"].includes(profile.gender) &&
        ["Male", "Female", "Both"].includes(profile.lookingFor)
      ) {
        writer.set(db.collection("publicProfiles").doc(uid), profile);
        publicProfilesWritten += 1;
      }

      const blockedUsers = Array.isArray(user.blockedUsers)
        ? user.blockedUsers
        : [];
      for (const blockedId of blockedUsers) {
        if (typeof blockedId !== "string" || blockedId === uid) continue;
        writer.set(db.collection("blocks").doc(`${uid}_${blockedId}`), {
          blockerId: uid,
          blockedId,
          createdAt: serverTimestamp(),
        });
        blockEdgesWritten += 1;
      }
    }

    await writer.close();
    return { publicProfilesWritten, blockEdgesWritten };
  },
);

exports.deleteMyAccount = onCall(
  {
    region: "asia-south1",
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (request) => {
    assertRecentLogin(request);
    const uid = request.auth.uid;

    const [chatsDeleted, outgoingBlocksDeleted, incomingBlocksDeleted] =
      await Promise.all([
        deleteQueryRecursively(
          db.collection("chats").where("participants", "array-contains", uid),
        ),
        deleteQueryDocuments(
          db.collection("blocks").where("blockerId", "==", uid),
        ),
        deleteQueryDocuments(
          db.collection("blocks").where("blockedId", "==", uid),
        ),
      ]);

    const [reporterReportsAnonymized, subjectReportsAnonymized] =
      await Promise.all([
        anonymizeReports(uid, "reporterId", {
          reporterName: "Deleted user",
          reporterPhoto: "",
        }),
        anonymizeReports(uid, "reportedUserId", {
          reportedUserName: "Deleted user",
          reportedUserPhoto: "",
        }),
      ]);

    await Promise.all([
      db.collection("publicProfiles").doc(uid).delete(),
      db.recursiveDelete(db.collection("users").doc(uid)),
    ]);

    try {
      await admin.auth().deleteUser(uid);
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
    }

    logger.info("Account deletion completed", {
      uid,
      chatsDeleted,
      outgoingBlocksDeleted,
      incomingBlocksDeleted,
      reporterReportsAnonymized,
      subjectReportsAnonymized,
    });

    return {
      success: true,
      chatsDeleted,
      reportsAnonymized:
        reporterReportsAnonymized + subjectReportsAnonymized,
    };
  },
);

exports.sendPrivateChatNotification = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: "asia-south1",
    retry: true,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const message = snapshot.data();
    const chatId = event.params.chatId;
    const senderId = message.senderId;
    const receiverId = message.receiverId;

    if (
      typeof senderId !== "string" ||
      typeof receiverId !== "string" ||
      senderId === receiverId ||
      message.isUnsent === true
    ) {
      logger.warn("Skipping malformed chat notification", {
        chatId,
        messageId: event.params.messageId,
      });
      return;
    }

    const [senderSnapshot, receiverSnapshot] = await Promise.all([
      db.collection("users").doc(senderId).get(),
      db.collection("users").doc(receiverId).get(),
    ]);
    if (!receiverSnapshot.exists) return;

    const receiver = receiverSnapshot.data() || {};
    const sender = senderSnapshot.data() || {};
    const senderBlocked = Array.isArray(sender.blockedUsers)
      ? sender.blockedUsers.includes(receiverId)
      : false;
    const receiverBlocked = Array.isArray(receiver.blockedUsers)
      ? receiver.blockedUsers.includes(senderId)
      : false;

    if (
      receiver.isSuspended === true ||
      receiver.messageNotificationsEnabled === false ||
      senderBlocked ||
      receiverBlocked
    ) {
      await snapshot.ref.update({
        pushProcessedAt: serverTimestamp(),
        pushDeliveryCount: 0,
        pushSkipped: true,
      });
      return;
    }

    const devicesSnapshot = await db
      .collection("users")
      .doc(receiverId)
      .collection("devices")
      .where("enabled", "==", true)
      .get();

    const devices = devicesSnapshot.docs
      .map((doc) => ({ ref: doc.ref, token: doc.get("token") }))
      .filter(
        (device) =>
          typeof device.token === "string" && device.token.length > 20,
      );

    if (devices.length === 0) {
      await snapshot.ref.update({
        pushProcessedAt: serverTimestamp(),
        pushDeliveryCount: 0,
        pushSkipped: false,
      });
      return;
    }

    const senderName =
      typeof sender.nickname === "string" && sender.nickname.trim().length > 0
        ? sender.nickname.trim()
        : "Someone nearby";

    let successfulDeliveries = 0;
    const invalidDeviceRefs = [];

    for (let start = 0; start < devices.length; start += 500) {
      const chunk = devices.slice(start, start + 500);
      const response = await messaging.sendEachForMulticast({
        tokens: chunk.map((device) => device.token),
        notification: {
          title: "New NearMeU message",
          body: `${senderName} sent you a message`,
        },
        data: { type: "private_chat", chatId, senderId },
        android: {
          priority: "high",
          notification: {
            channelId: "nearmeu_notifications",
            visibility: "private",
          },
        },
      });

      successfulDeliveries += response.successCount;
      response.responses.forEach((result, index) => {
        if (result.success) return;
        const code = result.error && result.error.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidDeviceRefs.push(chunk[index].ref);
        }
      });
    }

    if (invalidDeviceRefs.length > 0) {
      const writes = [];
      for (let start = 0; start < invalidDeviceRefs.length; start += 400) {
        const batch = db.batch();
        invalidDeviceRefs
          .slice(start, start + 400)
          .forEach((ref) => batch.delete(ref));
        writes.push(batch.commit());
      }
      await Promise.all(writes);
    }

    await snapshot.ref.update({
      pushProcessedAt: serverTimestamp(),
      pushDeliveryCount: successfulDeliveries,
      pushSkipped: false,
    });

    logger.info("Private chat push processed", {
      chatId,
      messageId: event.params.messageId,
      successfulDeliveries,
      invalidTokensRemoved: invalidDeviceRefs.length,
    });
  },
);
