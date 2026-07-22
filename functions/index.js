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

    await publicRef.set(
      publicProfileFromPrivate(event.params.userId, after.data() || {}),
      { merge: false },
    );
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
      writer.set(
        db.collection("publicProfiles").doc(uid),
        publicProfileFromPrivate(uid, user),
      );
      publicProfilesWritten += 1;

      const blockedUsers = Array.isArray(user.blockedUsers)
        ? user.blockedUsers
        : [];
      for (const blockedId of blockedUsers) {
        if (typeof blockedId !== "string" || blockedId === uid) continue;
        writer.set(db.collection("blocks").doc(`${uid}_${blockedId}`), {
          blockerId: uid,
          blockedId,
          createdAt: user.updatedAt || serverTimestamp(),
        });
        blockEdgesWritten += 1;
      }
    }

    await writer.close();
    return {
      publicProfilesWritten,
      blockEdgesWritten,
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
      .map((doc) => ({
        ref: doc.ref,
        token: doc.get("token"),
      }))
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
        data: {
          type: "private_chat",
          chatId,
          senderId,
        },
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
