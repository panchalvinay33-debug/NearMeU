const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.testConnection = onCall(async () => ({
  success: true,
  message: "NearMeU Cloud Functions Working",
}));

exports.getServerTime = onCall(async () => ({
  timestamp: Date.now(),
}));

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
        pushProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
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
      .filter((device) =>
        typeof device.token === "string" && device.token.length > 20,
      );

    if (devices.length === 0) {
      await snapshot.ref.update({
        pushProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
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
      const batches = [];
      for (let start = 0; start < invalidDeviceRefs.length; start += 400) {
        const batch = db.batch();
        invalidDeviceRefs
          .slice(start, start + 400)
          .forEach((ref) => batch.delete(ref));
        batches.push(batch.commit());
      }
      await Promise.all(batches);
    }

    await snapshot.ref.update({
      pushProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
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
