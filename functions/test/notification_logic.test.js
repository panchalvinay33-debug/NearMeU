const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildChatNotification,
  invalidTokenIndexes,
  sanitizePlatform,
  tokenDocumentId,
} = require("../notification_logic");

test("token document ids are deterministic hashes and never expose the raw token", () => {
  const token = "secret-fcm-token";
  const first = tokenDocumentId(token);
  const second = tokenDocumentId(token);

  assert.equal(first, second);
  assert.equal(first.length, 64);
  assert.equal(first.includes(token), false);
});

test("chat notification never includes private message text", () => {
  const payload = buildChatNotification({
    chatId: "alice_bob",
    senderId: "alice",
    senderName: "Alice",
    text: "this must never be sent",
  });

  assert.equal(payload.notification.title, "Alice");
  assert.equal(payload.notification.body, "You received a new private message.");
  assert.equal(JSON.stringify(payload).includes("this must never be sent"), false);
  assert.deepEqual(payload.data, {
    type: "private_chat",
    chatId: "alice_bob",
    senderId: "alice",
  });
});

test("unknown platforms are normalized", () => {
  assert.equal(sanitizePlatform("ANDROID"), "android");
  assert.equal(sanitizePlatform("playstation"), "unknown");
  assert.equal(sanitizePlatform(null), "unknown");
});

test("only permanently invalid FCM tokens are selected for deletion", () => {
  const indexes = invalidTokenIndexes([
    { success: true },
    {
      success: false,
      error: { code: "messaging/registration-token-not-registered" },
    },
    { success: false, error: { code: "messaging/internal-error" } },
    {
      success: false,
      error: { code: "messaging/invalid-registration-token" },
    },
  ]);

  assert.deepEqual(indexes, [1, 3]);
});
