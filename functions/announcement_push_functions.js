"use strict";

const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

const {
  buildAnnouncementNotification,
  invalidTokenIndexes,
  tokenDocumentId,
} = require("./notification_logic");

const db = admin.firestore();
const messaging = admin.messaging();
const REGION = "asia-south1";
const PAGE_LIMIT = 500;
const MULTICAST_LIMIT = 500;

async function activeOwnerIds(ownerIds) {
  const unique = [...new Set(ownerIds.filter(Boolean))];
  const active = new Set();
  for (let start = 0; start < unique.length; start += 400) {
    const chunk = unique.slice(start, start + 400);
    const snapshots = await db.getAll(
      ...chunk.map((uid) => db.collection("users").doc(uid)),
    );
    snapshots.forEach((snapshot) => {
      if (snapshot.exists && snapshot.get("isSuspended") !== true) {
        active.add(snapshot.id);
      }
    });
  }
  return active;
}

async function deleteInvalidDevices(devices, response) {
  const indexes = invalidTokenIndexes(response.responses);
  if (!indexes.length) return;
  const batch = db.batch();
  indexes.forEach((index) => {
    const device = devices[index];
    if (!device) return;
    batch.delete(device.ref);
    batch.delete(db.collection("deviceTokenOwners").doc(tokenDocumentId(device.token)));
  });
  await batch.commit();
}

exports.sendSupportAnnouncementNotification = onDocumentCreated(
  {
    document: "supportAnnouncements/{announcementId}",
    region: REGION,
    retry: false,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const announcement = snapshot.data() || {};
    if (
      announcement.isActive !== true ||
      announcement.targetAudience !== "allActiveUsers"
    ) {
      return;
    }

    const payload = buildAnnouncementNotification({
      announcementId: event.params.announcementId,
      title: announcement.title,
      message: announcement.message,
      priority: announcement.priority,
    });

    let cursor = null;
    let deliveredDevices = 0;
    while (true) {
      let query = db
        .collectionGroup("devices")
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(PAGE_LIMIT);
      if (cursor) query = query.startAfter(cursor);
      const page = await query.get();
      if (page.empty) break;

      const devices = page.docs
        .map((document) => ({
          ref: document.ref,
          ownerId: document.get("ownerId"),
          token: document.get("token"),
        }))
        .filter(
          (device) =>
            typeof device.ownerId === "string" &&
            device.ownerId.length > 0 &&
            typeof device.token === "string" &&
            device.token.length > 0,
        );
      const activeOwners = await activeOwnerIds(devices.map((item) => item.ownerId));
      const eligible = devices.filter((item) => activeOwners.has(item.ownerId));

      for (let start = 0; start < eligible.length; start += MULTICAST_LIMIT) {
        const chunk = eligible.slice(start, start + MULTICAST_LIMIT);
        const response = await messaging.sendEachForMulticast({
          ...payload,
          tokens: chunk.map((item) => item.token),
        });
        deliveredDevices += response.successCount;
        await deleteInvalidDevices(chunk, response);
      }

      cursor = page.docs[page.docs.length - 1];
      if (page.size < PAGE_LIMIT) break;
    }

    logger.info("Support announcement push processed", {
      announcementId: event.params.announcementId,
      deliveredDevices,
    });
  },
);
