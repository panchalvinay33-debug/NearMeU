"use strict";

const crypto = require("node:crypto");
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const {
  REPORT_WINDOW_MS,
  isWithinReportCooldown,
  messageRateDecision,
  normalizedMessage,
  normalizedReply,
  normalizedReport,
  normalizedUserId,
  reportRateDecision,
} = require("./anti_abuse_logic");

const db = admin.firestore();
const REGION = "asia-south1";

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : null;
}

function deterministicChatId(firstId, secondId) {
  return [firstId, secondId].sort().join("_");
}

function hashedId(...parts) {
  return crypto.createHash("sha256").update(parts.join("\u0000")).digest("hex");
}

function activeProfile(snapshot, uid) {
  if (!snapshot.exists) {
    throw new HttpsError("failed-precondition", "An active NearMeU profile is required.");
  }
  if (snapshot.get("isSuspended") === true) {
    throw new HttpsError("permission-denied", "This account is suspended.");
  }
  const age = snapshot.get("age");
  if (!Number.isInteger(age) || age < 18) {
    throw new HttpsError("failed-precondition", "An adult NearMeU profile is required.");
  }
  if (snapshot.id !== uid) {
    throw new HttpsError("failed-precondition", "Profile identity is invalid.");
  }
}

async function recordRateLimitAudit({ actorId, targetUserId, eventType, details }) {
  const minuteBucket = Math.floor(Date.now() / 60000);
  const ref = db
    .collection("moderationAuditLogs")
    .doc(hashedId(actorId, eventType, String(minuteBucket)));
  await ref.set(
    {
      actorId,
      targetUserId: targetUserId || null,
      eventType,
      details: details || {},
      occurrenceCount: admin.firestore.FieldValue.increment(1),
      firstOccurredAt: admin.firestore.FieldValue.serverTimestamp(),
      lastOccurredAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "trusted_backend",
    },
    { merge: true },
  );
}

exports.sendPrivateMessage = onCall({ region: REGION }, async (request) => {
  const senderId = requireAuthenticatedUid(request);
  let receiverId;
  let text;
  let reply;

  try {
    receiverId = normalizedUserId(request.data && request.data.receiverId, "receiverId");
    text = normalizedMessage(request.data && request.data.text);
    if (senderId === receiverId) {
      throw new TypeError("You cannot chat with yourself.");
    }
    reply = normalizedReply(
      request.data && request.data.replyTo,
      [senderId, receiverId],
    );
  } catch (error) {
    throw new HttpsError("invalid-argument", error.message);
  }

  const chatId = deterministicChatId(senderId, receiverId);
  const participants = [senderId, receiverId].sort();
  const chatRef = db.collection("chats").doc(chatId);
  const messageRef = chatRef.collection("messages").doc();
  const senderRef = db.collection("users").doc(senderId);
  const receiverRef = db.collection("users").doc(receiverId);
  const blockedBySenderRef = senderRef.collection("blocks").doc(receiverId);
  const blockedByReceiverRef = receiverRef.collection("blocks").doc(senderId);
  const abuseRef = db.collection("antiAbuseUsers").doc(senderId);

  try {
    await db.runTransaction(async (transaction) => {
      const [
        senderSnapshot,
        receiverSnapshot,
        blockedBySender,
        blockedByReceiver,
        chatSnapshot,
        abuseSnapshot,
      ] = await Promise.all([
        transaction.get(senderRef),
        transaction.get(receiverRef),
        transaction.get(blockedBySenderRef),
        transaction.get(blockedByReceiverRef),
        transaction.get(chatRef),
        transaction.get(abuseRef),
      ]);

      activeProfile(senderSnapshot, senderId);
      activeProfile(receiverSnapshot, receiverId);
      if (blockedBySender.exists || blockedByReceiver.exists) {
        throw new HttpsError("permission-denied", "Messaging is unavailable for this chat.");
      }

      const now = admin.firestore.Timestamp.now();
      const nowMs = now.toMillis();
      const abuseData = abuseSnapshot.exists ? abuseSnapshot.data() : {};
      const rate = messageRateDecision({
        nowMs,
        lastMessageAtMs: timestampMillis(abuseData.lastMessageAt),
        windowStartedAtMs: timestampMillis(abuseData.messageWindowStartedAt),
        count: abuseData.messageCount,
      });
      if (!rate.allowed) {
        throw new HttpsError(
          "resource-exhausted",
          "Please slow down before sending more messages.",
          {
            reason: rate.reason,
            retryAfterSeconds: Math.max(1, Math.ceil(rate.retryAfterMs / 1000)),
          },
        );
      }

      const existingData = chatSnapshot.exists ? chatSnapshot.data() : null;
      if (existingData) {
        const existingParticipants = Array.isArray(existingData.participants)
          ? [...existingData.participants].sort()
          : [];
        if (
          existingParticipants.length !== 2 ||
          existingParticipants[0] !== participants[0] ||
          existingParticipants[1] !== participants[1]
        ) {
          throw new HttpsError("failed-precondition", "Invalid chat room.");
        }
      }

      const unreadCounts = existingData && existingData.unreadCounts
        ? { ...existingData.unreadCounts }
        : {};
      const readStates = existingData && existingData.readStates
        ? { ...existingData.readStates }
        : {};
      const nextReceiverUnread = Number.isInteger(unreadCounts[receiverId])
        ? unreadCounts[receiverId] + 1
        : 1;
      unreadCounts[senderId] = 0;
      unreadCounts[receiverId] = nextReceiverUnread;
      readStates[senderId] = {
        ...(readStates[senderId] || {}),
        lastReadAt: now,
        lastReadMessageId: messageRef.id,
        unreadCount: 0,
      };
      readStates[receiverId] = {
        ...(readStates[receiverId] || {}),
        unreadCount: nextReceiverUnread,
      };

      const chatData = {
        participants,
        lastMessage: text,
        lastMessageTime: now,
        latestMessageAt: now,
        lastMessageSenderId: senderId,
        latestSenderId: senderId,
        lastMessageType: "text",
        lastMessageIsUnsent: false,
        unreadCounts,
        readStates,
      };
      if (chatSnapshot.exists) {
        transaction.update(chatRef, chatData);
      } else {
        transaction.set(chatRef, { ...chatData, createdAt: now });
      }

      transaction.set(messageRef, {
        senderId,
        receiverId,
        text,
        timestamp: now,
        isUnsent: false,
        unsentAt: null,
        replyToMessageId: reply && reply.messageId,
        replyToText: reply && reply.text,
        replyToSenderId: reply && reply.senderId,
        type: "text",
        mediaUrl: null,
        isSeen: false,
        seenAt: null,
        deletedFor: [],
      });

      transaction.set(
        abuseRef,
        {
          messageWindowStartedAt: admin.firestore.Timestamp.fromMillis(
            rate.windowStartedAtMs,
          ),
          messageCount: rate.count,
          lastMessageAt: now,
          updatedAt: now,
        },
        { merge: true },
      );
    });
  } catch (error) {
    if (error instanceof HttpsError && error.code === "resource-exhausted") {
      try {
        await recordRateLimitAudit({
          actorId: senderId,
          targetUserId: receiverId,
          eventType: "message_rate_limited",
          details: error.details || {},
        });
      } catch (auditError) {
        logger.error("Unable to write message rate-limit audit", {
          senderId,
          auditError,
        });
      }
    }
    throw error;
  }

  return { success: true, chatId, messageId: messageRef.id };
});

exports.moderateNewReport = onDocumentCreated(
  {
    document: "reports/{reportId}",
    region: REGION,
    retry: false,
  },
  async (event) => {
    const reportSnapshot = event.data;
    if (!reportSnapshot) return;

    const reportId = event.params.reportId;
    const data = reportSnapshot.data();
    const now = admin.firestore.Timestamp.now();
    const nowMs = now.toMillis();
    let reporterId;
    let reportedUserId;
    let normalized;

    try {
      reporterId = normalizedUserId(data.reporterId, "reporterId");
      reportedUserId = normalizedUserId(data.reportedUserId, "reportedUserId");
      if (reporterId === reportedUserId) throw new TypeError("Self-report is invalid.");
      normalized = normalizedReport(data.reason, data.description);
    } catch (error) {
      await reportSnapshot.ref.set(
        {
          status: "rejected",
          action: "invalid_payload",
          reviewedAt: now,
          reviewedBy: "system",
        },
        { merge: true },
      );
      logger.warn("Rejected invalid report payload", { reportId, error: error.message });
      return;
    }

    const reporterRef = db.collection("users").doc(reporterId);
    const reportedRef = db.collection("users").doc(reportedUserId);
    const abuseRef = db.collection("antiAbuseUsers").doc(reporterId);
    const lockRef = db
      .collection("reportLocks")
      .doc(hashedId(reporterId, reportedUserId));
    const auditRef = db.collection("moderationAuditLogs").doc();

    await db.runTransaction(async (transaction) => {
      const [reporter, reported, abuse, lock] = await Promise.all([
        transaction.get(reporterRef),
        transaction.get(reportedRef),
        transaction.get(abuseRef),
        transaction.get(lockRef),
      ]);

      try {
        activeProfile(reporter, reporterId);
      } catch (error) {
        transaction.set(
          reportSnapshot.ref,
          {
            status: "rejected",
            action: "inactive_reporter",
            reviewedAt: now,
            reviewedBy: "system",
          },
          { merge: true },
        );
        return;
      }
      if (!reported.exists || reported.get("isSuspended") === true) {
        transaction.set(
          reportSnapshot.ref,
          {
            status: "rejected",
            action: "unavailable_target",
            reviewedAt: now,
            reviewedBy: "system",
          },
          { merge: true },
        );
        return;
      }

      const abuseData = abuse.exists ? abuse.data() : {};
      const rate = reportRateDecision({
        nowMs,
        windowStartedAtMs: timestampMillis(abuseData.reportWindowStartedAt),
        count: abuseData.reportCount,
      });
      const lockData = lock.exists ? lock.data() : {};
      const duplicatePending = lockData.status === "pending";
      const withinCooldown = isWithinReportCooldown(
        nowMs,
        timestampMillis(lockData.lastReportAt),
      );

      let rejectionAction = null;
      if (!rate.allowed) rejectionAction = "report_rate_limited";
      else if (duplicatePending) rejectionAction = "duplicate_pending_report";
      else if (withinCooldown) rejectionAction = "repeat_report_cooldown";

      if (rejectionAction) {
        const restrictedUntil = !rate.allowed
          ? admin.firestore.Timestamp.fromMillis(
              rate.windowStartedAtMs + REPORT_WINDOW_MS,
            )
          : null;
        transaction.set(
          reportSnapshot.ref,
          {
            status: "rejected",
            action: rejectionAction,
            reviewedAt: now,
            reviewedBy: "system",
          },
          { merge: true },
        );
        transaction.set(
          abuseRef,
          {
            ...(restrictedUntil ? { reportRestrictedUntil: restrictedUntil } : {}),
            updatedAt: now,
          },
          { merge: true },
        );
        transaction.set(auditRef, {
          actorId: reporterId,
          targetUserId: reportedUserId,
          reportId,
          eventType: rejectionAction,
          details: {},
          occurredAt: now,
          source: "trusted_backend",
        });
        return;
      }

      transaction.set(
        reportSnapshot.ref,
        {
          reporterName: reporter.get("nickname") || "",
          reporterPhoto: reporter.get("photoUrl") || "",
          reportedUserName: reported.get("nickname") || "",
          reportedUserPhoto: reported.get("photoUrl") || "",
          reason: normalized.reason,
          description: normalized.description,
          status: "pending",
          reviewedAt: null,
          reviewedBy: null,
          action: null,
        },
        { merge: true },
      );
      transaction.set(
        abuseRef,
        {
          reportWindowStartedAt: admin.firestore.Timestamp.fromMillis(
            rate.windowStartedAtMs,
          ),
          reportCount: rate.count,
          reportRestrictedUntil: admin.firestore.FieldValue.delete(),
          updatedAt: now,
        },
        { merge: true },
      );
      transaction.set(lockRef, {
        reporterId,
        reportedUserId,
        reportId,
        status: "pending",
        lastReportAt: now,
        updatedAt: now,
      });
      transaction.set(auditRef, {
        actorId: reporterId,
        targetUserId: reportedUserId,
        reportId,
        eventType: "report_submitted",
        details: { reason: normalized.reason },
        occurredAt: now,
        source: "trusted_backend",
      });
    });
  },
);

exports.syncResolvedReportLock = onDocumentUpdated(
  {
    document: "reports/{reportId}",
    region: REGION,
    retry: false,
  },
  async (event) => {
    const before = event.data && event.data.before.data();
    const after = event.data && event.data.after.data();
    if (!before || !after || before.status === after.status || after.status !== "resolved") {
      return;
    }

    let reporterId;
    let reportedUserId;
    try {
      reporterId = normalizedUserId(after.reporterId, "reporterId");
      reportedUserId = normalizedUserId(after.reportedUserId, "reportedUserId");
    } catch (_) {
      return;
    }

    const now = admin.firestore.Timestamp.now();
    await db
      .collection("reportLocks")
      .doc(hashedId(reporterId, reportedUserId))
      .set(
        {
          reporterId,
          reportedUserId,
          reportId: event.params.reportId,
          status: "resolved",
          resolvedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );
  },
);
