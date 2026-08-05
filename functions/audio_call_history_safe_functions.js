"use strict";

const admin = require("firebase-admin");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

const db = admin.firestore();
const REGION = "asia-south1";
const TERMINAL = new Set(["declined", "ended", "missed", "expired"]);

function deterministicChatId(a, b) {
  return [a, b].sort().join("_");
}

function durationLabel(ms) {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  if (minutes > 0) return `${minutes}:${String(seconds).padStart(2, "0")}`;
  return `0:${String(seconds).padStart(2, "0")}`;
}

function historyText(data) {
  if (data.status === "declined") return "Audio call declined";
  if (data.status === "missed") return "Missed audio call";
  if (data.status === "expired") return "Audio call ended";
  const accepted = Number(data.acceptedAtMillis || 0);
  const ended = Number(data.endedAtMillis || 0);
  if (accepted > 0 && ended >= accepted) {
    return `Audio call • ${durationLabel(ended - accepted)}`;
  }
  return "Audio call ended";
}

exports.writeAudioCallHistorySafe = onDocumentUpdated(
  {
    document: "audioCalls/{callId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const before = event.data && event.data.before;
    const after = event.data && event.data.after;
    if (!before || !after || !after.exists) return;

    const previous = before.data() || {};
    const data = after.data() || {};
    if (!TERMINAL.has(data.status) || previous.status === data.status) return;

    const callerUid = typeof data.callerUid === "string" ? data.callerUid : "";
    const calleeUid = typeof data.calleeUid === "string" ? data.calleeUid : "";
    if (!callerUid || !calleeUid || callerUid === calleeUid) return;

    const callId = event.params.callId;
    const chatId = deterministicChatId(callerUid, calleeUid);
    const chatRef = db.collection("chats").doc(chatId);
    const messageRef = chatRef.collection("messages").doc(`call_${callId}`);
    const text = historyText(data);
    const timestamp = data.endedAtMillis
      ? admin.firestore.Timestamp.fromMillis(Number(data.endedAtMillis))
      : admin.firestore.Timestamp.now();

    await db.runTransaction(async (tx) => {
      const [chatSnap, messageSnap] = await Promise.all([
        tx.get(chatRef),
        tx.get(messageRef),
      ]);
      if (messageSnap.exists) return;

      const existing = chatSnap.exists ? chatSnap.data() || {} : {};
      const participants = [callerUid, calleeUid].sort();
      const chatPatch = {
        participants,
        lastMessage: text,
        lastMessageTime: timestamp,
        latestMessageAt: timestamp,
        lastMessageSenderId: callerUid,
        latestSenderId: callerUid,
        lastMessageType: "text",
        lastMessageIsUnsent: false,
      };
      if (chatSnap.exists) tx.update(chatRef, chatPatch);
      else tx.set(chatRef, { ...chatPatch, createdAt: timestamp });

      tx.set(messageRef, {
        senderId: callerUid,
        receiverId: calleeUid,
        text,
        timestamp,
        isUnsent: false,
        unsentAt: null,
        replyToMessageId: null,
        replyToText: null,
        replyToSenderId: null,
        type: "text",
        mediaUrl: null,
        mediaStoragePath: null,
        mediaContentType: null,
        mediaSizeBytes: null,
        mediaDurationMs: null,
        downloadAcknowledgements: {},
        cloudExpiresAt: null,
        cloudMediaDeletedAt: null,
        isDelivered: true,
        deliveredAt: timestamp,
        isSeen: true,
        seenAt: timestamp,
        deletedFor: [],
        systemEvent: "audio_call",
        callId,
        callStatus: data.status,
      });
    });
  },
);
