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

function invalidTokenIndexes(responses) {
  const indexes = [];
  responses.forEach((response, index) => {
    const code = response && response.error && response.error.code;
    if (!response.success && INVALID_TOKEN_CODES.has(code)) indexes.push(index);
  });
  return indexes;
}

module.exports = {
  buildChatNotification,
  invalidTokenIndexes,
  sanitizePlatform,
  tokenDocumentId,
};
