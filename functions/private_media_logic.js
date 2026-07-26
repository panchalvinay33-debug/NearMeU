"use strict";

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const MAX_VIDEO_BYTES = 30 * 1024 * 1024;
const MAX_VOICE_BYTES = 8 * 1024 * 1024;
const MAX_VIDEO_DURATION_MS = 2 * 60 * 1000;
const MAX_VOICE_DURATION_MS = 2 * 60 * 1000;
const MAX_CAPTION_LENGTH = 500;
const MESSAGE_ID_PATTERN = /^[A-Za-z0-9_-]{10,64}$/;

function requiredString(value, fieldName, maxLength = 256) {
  if (typeof value !== "string") {
    throw new TypeError(`${fieldName} is required.`);
  }
  const normalized = value.trim();
  if (!normalized || normalized.length > maxLength) {
    throw new TypeError(`${fieldName} is invalid.`);
  }
  return normalized;
}

function deterministicChatId(firstId, secondId) {
  return [firstId, secondId].sort().join("_");
}

function validMessageId(value) {
  const messageId = requiredString(value, "messageId", 64);
  if (!MESSAGE_ID_PATTERN.test(messageId)) {
    throw new TypeError("messageId is invalid.");
  }
  return messageId;
}

function normalizePrivateMediaRequest(data, senderId) {
  const payload = data && typeof data === "object" ? data : {};
  const receiverId = requiredString(payload.receiverId, "receiverId", 128);
  if (receiverId === senderId) {
    throw new TypeError("You cannot send media to yourself.");
  }

  const messageId = validMessageId(payload.messageId);
  const type = requiredString(payload.type, "type", 16);
  if (type !== "image" && type !== "video" && type !== "voice") {
    throw new TypeError("Only image, video and voice messages are supported.");
  }

  const chatId = deterministicChatId(senderId, receiverId);
  const storagePath = requiredString(payload.storagePath, "storagePath", 512);
  const expectedPrefix = `privateChatMedia/${senderId}/${chatId}/${messageId}/`;
  if (!storagePath.startsWith(expectedPrefix)) {
    throw new TypeError("storagePath does not belong to this private message.");
  }

  const caption = typeof payload.caption === "string" ? payload.caption.trim() : "";
  if (caption.length > MAX_CAPTION_LENGTH) {
    throw new TypeError("Caption is too long.");
  }
  if (type === "voice" && caption) {
    throw new TypeError("Voice messages do not support captions.");
  }

  const needsDuration = type === "video" || type === "voice";
  const durationMs = needsDuration ? Number(payload.durationMs) : null;
  const maximumDuration = type === "voice"
    ? MAX_VOICE_DURATION_MS
    : MAX_VIDEO_DURATION_MS;
  if (
    needsDuration &&
    (!Number.isFinite(durationMs) || durationMs <= 0 || durationMs > maximumDuration)
  ) {
    throw new TypeError(
      type === "voice"
        ? "Voice message must be two minutes or shorter."
        : "Video must be two minutes or shorter.",
    );
  }

  return {
    receiverId,
    messageId,
    type,
    chatId,
    storagePath,
    caption,
    durationMs: durationMs === null ? null : Math.trunc(durationMs),
  };
}

function normalizeDownloadAcknowledgement(data) {
  const payload = data && typeof data === "object" ? data : {};
  return {
    chatId: requiredString(payload.chatId, "chatId", 300),
    messageId: validMessageId(payload.messageId),
  };
}

function validateStoredMedia({
  type,
  sizeBytes,
  contentType,
  metadata,
  senderId,
  receiverId,
  chatId,
  messageId,
}) {
  const size = Number(sizeBytes);
  if (!Number.isFinite(size) || size <= 0) {
    throw new TypeError("Uploaded media is empty.");
  }

  const allowedContentTypes = type === "image"
    ? new Set(["image/jpeg", "image/png", "image/webp"])
    : type === "video"
      ? new Set(["video/mp4"])
      : new Set(["audio/mp4", "audio/m4a", "audio/aac"]);
  if (!allowedContentTypes.has(contentType)) {
    throw new TypeError("Uploaded media format is not supported.");
  }

  const maximumBytes = type === "image"
    ? MAX_IMAGE_BYTES
    : type === "video"
      ? MAX_VIDEO_BYTES
      : MAX_VOICE_BYTES;
  if (size > maximumBytes) {
    throw new TypeError(
      type === "image"
        ? "Photo is larger than 5 MB."
        : type === "video"
          ? "Compressed video is larger than 30 MB."
          : "Voice message is larger than 8 MB.",
    );
  }

  const custom = metadata && typeof metadata === "object" ? metadata : {};
  const expected = {
    senderId,
    receiverId,
    chatId,
    messageId,
    mediaType: type,
  };
  for (const [key, value] of Object.entries(expected)) {
    if (custom[key] !== value) {
      throw new TypeError("Uploaded media metadata is invalid.");
    }
  }

  return {
    sizeBytes: Math.trunc(size),
    contentType,
  };
}

module.exports = {
  MAX_CAPTION_LENGTH,
  MAX_IMAGE_BYTES,
  MAX_VIDEO_BYTES,
  MAX_VOICE_BYTES,
  MAX_VIDEO_DURATION_MS,
  MAX_VOICE_DURATION_MS,
  deterministicChatId,
  normalizeDownloadAcknowledgement,
  normalizePrivateMediaRequest,
  validateStoredMedia,
};
