const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildAnnouncementNotification,
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

test("chat notification hides sender identity and private message text", () => {
  const payload = buildChatNotification({
    chatId: "alice_bob",
    senderId: "alice",
    senderName: "Alice",
    text: "this must never be sent",
  });
  const serialized = JSON.stringify(payload);

  assert.equal(payload.notification.title, "NearMeU");
  assert.equal(payload.notification.body, "You received a new private message.");
  assert.equal(serialized.includes("this must never be sent"), false);
  assert.equal(serialized.includes("Alice"), false);
  assert.equal(serialized.includes('"senderId"'), false);
  assert.equal(payload.android.notification.visibility, "private");
  assert.deepEqual(payload.data, {
    type: "private_chat",
    chatId: "alice_bob",
  });
});

test("announcement notification carries a safe support route", () => {
  const payload = buildAnnouncementNotification({
    announcementId: "announcement_1",
    title: "New NearMeU update",
    message: "Open support announcements to see what changed.",
    priority: "important",
  });

  assert.equal(payload.notification.title, "New NearMeU update");
  assert.equal(
    payload.notification.body,
    "Open support announcements to see what changed.",
  );
  assert.deepEqual(payload.data, {
    type: "support_announcement",
    announcementId: "announcement_1",
  });
  assert.equal(payload.android.notification.visibility, "private");
});

test("announcement notification applies bounded fallbacks", () => {
  const payload = buildAnnouncementNotification({
    announcementId: "announcement_2",
    title: " ",
    message: "x".repeat(300),
    priority: "urgent",
  });

  assert.equal(payload.notification.title, "NearMeU Update");
  assert.equal(payload.notification.body.length, 180);
  assert.equal(payload.android.notification.priority, "max");
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
