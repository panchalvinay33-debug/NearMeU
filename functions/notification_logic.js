const crypto = require("node:crypto");

const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

function tokenDocumentId(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function sanitizePlatform(value) {
  const platform = typeof value === "string" ? value.trim().toLowerCase() : "";
  return ["android", "ios", "macos", "windows", "linux", "web"].includes(platform)
    ? platform
    : "unknown";
}

function buildChatNotification({ chatId }) {
  return {
    notification: {
      title: "NearMeU",
      body: "You received a new private message.",
    },
    data: {
      type: "private_chat",
      chatId: String(chatId),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "nearmeu_notifications",
        sound: "default",
        visibility: "private",
      },
    },
  };
}

function cleanText(value, fallback, maximumLength) {
  const text = typeof value === "string" ? value.trim() : "";
  if (!text) return fallback;
  return text.slice(0, maximumLength);
}

function buildAnnouncementNotification({
  announcementId,
  title,
  message,
  priority,
}) {
  const urgent = priority === "urgent";
  return {
    notification: {
      title: cleanText(title, "NearMeU Update", 80),
      body: cleanText(message, "A new official announcement is available.", 180),
    },
    data: {
      type: "support_announcement",
      announcementId: String(announcementId),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "nearmeu_notifications",
        sound: "default",
        visibility: "private",
        ...(urgent ? { priority: "max" } : {}),
      },
    },
  };
}

function invalidTokenIndexes(responses) {
  const indexes = [];
  responses.forEach((response, index) => {
    const code = response && response.error && response.error.code;
    if (!response.success && INVALID_TOKEN_CODES.has(code)) indexes.push(index);
  });
  return indexes;
}

module.exports = {
  buildAnnouncementNotification,
  buildChatNotification,
  invalidTokenIndexes,
  sanitizePlatform,
  tokenDocumentId,
};
