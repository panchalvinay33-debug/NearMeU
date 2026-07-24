"use strict";

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const MAX_VIDEO_BYTES = 30 * 1024 * 1024;
const MAX_VIDEO_DURATION_MS = 2 * 60 * 1000;
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

function normalizePrivateMediaRequest(data, senderId) {
  const payload = data && typeof data === "object" ? data : {};
  const receiverId = requiredString(payload.receiverId, "receiverId", 128);
  if (receiverId === senderId) {
    throw new TypeError("You cannot send media to yourself.");
  }

  const messageId = requiredString(payload.messageId, "messageId", 64);
  if (!MESSAGE_ID_PATTERN.test(messageId)) {
    throw new TypeError("messageId is invalid.");
  }

  const type = requiredString(payload.type, "type", 16);
  if (type !== "image" && type !== "video") {
    throw new TypeError("Only image and video messages are supported.");
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

  const durationMs = type === "video" ? Number(payload.durationMs) : null;
  if (
    type === "video" &&
    (!Number.isFinite(durationMs) ||
      durationMs <= 0 ||
      durationMs > MAX_VIDEO_DURATION_MS)
  ) {
    throw new TypeError("Video must be two minutes or shorter.");
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
    : new Set(["video/mp4"]);
  if (!allowedContentTypes.has(contentType)) {
    throw new TypeError("Uploaded media format is not supported.");
  }

  const maximumBytes = type === "image" ? MAX_IMAGE_BYTES : MAX_VIDEO_BYTES;
  if (size > maximumBytes) {
    throw new TypeError(
      type === "image"
        ? "Photo is larger than 5 MB."
        : "Compressed video is larger than 30 MB.",
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
  MAX_VIDEO_DURATION_MS,
  deterministicChatId,
  normalizePrivateMediaRequest,
  validateStoredMedia,
};
