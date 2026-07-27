"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  MAX_IMAGE_BYTES,
  MAX_VIDEO_BYTES,
  MAX_VOICE_BYTES,
  MAX_VIDEO_DURATION_MS,
  MAX_VOICE_DURATION_MS,
  deterministicChatId,
  normalizeDownloadAcknowledgement,
  normalizePrivateMediaRequest,
  validateStoredMedia,
} = require("./private_media_logic");

function request({ type = "image", durationMs = null, caption = "Hello" } = {}) {
  const senderId = "sender-user";
  const receiverId = "receiver-user";
  const messageId = "message_1234567890";
  const chatId = deterministicChatId(senderId, receiverId);
  return {
    senderId,
    receiverId,
    messageId,
    chatId,
    payload: {
      receiverId,
      messageId,
      type,
      durationMs,
      caption,
      storagePath:
        `privateChatMedia/${senderId}/${chatId}/${messageId}/upload.bin`,
    },
  };
}

test("normalizes an image request into its deterministic private path", () => {
  const input = request();
  const normalized = normalizePrivateMediaRequest(
    input.payload,
    input.senderId,
  );
  assert.equal(normalized.chatId, input.chatId);
  assert.equal(normalized.type, "image");
  assert.equal(normalized.durationMs, null);
});

test("rejects a media path owned by another sender or message", () => {
  const input = request();
  input.payload.storagePath =
    `privateChatMedia/another-user/${input.chatId}/${input.messageId}/photo.jpg`;
  assert.throws(
    () => normalizePrivateMediaRequest(input.payload, input.senderId),
    /storagePath/,
  );
});

test("video duration is capped at two minutes", () => {
  const allowed = request({ type: "video", durationMs: MAX_VIDEO_DURATION_MS });
  assert.doesNotThrow(() =>
    normalizePrivateMediaRequest(allowed.payload, allowed.senderId),
  );

  const tooLong = request({
    type: "video",
    durationMs: MAX_VIDEO_DURATION_MS + 1,
  });
  assert.throws(
    () => normalizePrivateMediaRequest(tooLong.payload, tooLong.senderId),
    /two minutes/,
  );
});

test("voice duration and caption rules are enforced", () => {
  const allowed = request({
    type: "voice",
    durationMs: MAX_VOICE_DURATION_MS,
    caption: "",
  });
  assert.doesNotThrow(() =>
    normalizePrivateMediaRequest(allowed.payload, allowed.senderId),
  );

  const tooLong = request({
    type: "voice",
    durationMs: MAX_VOICE_DURATION_MS + 1,
    caption: "",
  });
  assert.throws(
    () => normalizePrivateMediaRequest(tooLong.payload, tooLong.senderId),
    /two minutes/,
  );

  const captioned = request({
    type: "voice",
    durationMs: 5000,
    caption: "not allowed",
  });
  assert.throws(
    () => normalizePrivateMediaRequest(captioned.payload, captioned.senderId),
    /captions/,
  );
});

test("download acknowledgements require a valid chat and message ID", () => {
  const input = request();
  assert.deepEqual(
    normalizeDownloadAcknowledgement({
      chatId: input.chatId,
      messageId: input.messageId,
    }),
    {
      chatId: input.chatId,
      messageId: input.messageId,
    },
  );
  assert.throws(
    () =>
      normalizeDownloadAcknowledgement({
        chatId: input.chatId,
        messageId: "bad id",
      }),
    /messageId/,
  );
});

test("stored media must match size, type and private metadata", () => {
  const input = request();
  const metadata = {
    senderId: input.senderId,
    receiverId: input.receiverId,
    chatId: input.chatId,
    messageId: input.messageId,
    mediaType: "image",
  };
  assert.deepEqual(
    validateStoredMedia({
      type: "image",
      sizeBytes: MAX_IMAGE_BYTES,
      contentType: "image/jpeg",
      metadata,
      senderId: input.senderId,
      receiverId: input.receiverId,
      chatId: input.chatId,
      messageId: input.messageId,
    }),
    { sizeBytes: MAX_IMAGE_BYTES, contentType: "image/jpeg" },
  );

  assert.throws(
    () =>
      validateStoredMedia({
        type: "image",
        sizeBytes: MAX_IMAGE_BYTES + 1,
        contentType: "image/jpeg",
        metadata,
        senderId: input.senderId,
        receiverId: input.receiverId,
        chatId: input.chatId,
        messageId: input.messageId,
      }),
    /5 MB/,
  );
});

test("compressed videos are capped at 30 MB and MP4", () => {
  const input = request({ type: "video", durationMs: 60000 });
  const metadata = {
    senderId: input.senderId,
    receiverId: input.receiverId,
    chatId: input.chatId,
    messageId: input.messageId,
    mediaType: "video",
  };
  assert.doesNotThrow(() =>
    validateStoredMedia({
      type: "video",
      sizeBytes: MAX_VIDEO_BYTES,
      contentType: "video/mp4",
      metadata,
      senderId: input.senderId,
      receiverId: input.receiverId,
      chatId: input.chatId,
      messageId: input.messageId,
    }),
  );
  assert.throws(
    () =>
      validateStoredMedia({
        type: "video",
        sizeBytes: 1024,
        contentType: "video/quicktime",
        metadata,
        senderId: input.senderId,
        receiverId: input.receiverId,
        chatId: input.chatId,
        messageId: input.messageId,
      }),
    /format/,
  );
});

test("voice files are capped at 8 MB and use an allowed audio type", () => {
  const input = request({ type: "voice", durationMs: 5000, caption: "" });
  const metadata = {
    senderId: input.senderId,
    receiverId: input.receiverId,
    chatId: input.chatId,
    messageId: input.messageId,
    mediaType: "voice",
  };
  assert.doesNotThrow(() =>
    validateStoredMedia({
      type: "voice",
      sizeBytes: MAX_VOICE_BYTES,
      contentType: "audio/mp4",
      metadata,
      senderId: input.senderId,
      receiverId: input.receiverId,
      chatId: input.chatId,
      messageId: input.messageId,
    }),
  );
  assert.throws(
    () =>
      validateStoredMedia({
        type: "voice",
        sizeBytes: MAX_VOICE_BYTES + 1,
        contentType: "audio/mp4",
        metadata,
        senderId: input.senderId,
        receiverId: input.receiverId,
        chatId: input.chatId,
        messageId: input.messageId,
      }),
    /8 MB/,
  );
});
