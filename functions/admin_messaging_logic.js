"use strict";

const MESSAGE_TYPES = ["text", "image", "video", "voice"];

function safeNumber(value) {
  return typeof value === "number" && Number.isFinite(value) && value >= 0
    ? value
    : 0;
}

function percent(part, whole) {
  if (!whole) return 0;
  return Math.round((part / whole) * 10000) / 100;
}

function buildMessagingHealthMetrics(rows) {
  const metrics = {
    sampledMessages: 0,
    deliveredMessages: 0,
    seenMessages: 0,
    unsentMessages: 0,
    deliveryRatePercent: 0,
    seenRatePercent: 0,
    types: { text: 0, image: 0, video: 0, voice: 0, other: 0 },
    mediaMessages: 0,
    mediaBytes: 0,
    voiceMessages: 0,
    voiceDurationMs: 0,
    pendingMediaCleanup: 0,
  };

  for (const row of rows || []) {
    metrics.sampledMessages += 1;
    if (row.isDelivered === true || row.isSeen === true) {
      metrics.deliveredMessages += 1;
    }
    if (row.isSeen === true) metrics.seenMessages += 1;
    if (row.isUnsent === true) metrics.unsentMessages += 1;

    const type = typeof row.type === "string" ? row.type : "text";
    if (MESSAGE_TYPES.includes(type)) metrics.types[type] += 1;
    else metrics.types.other += 1;

    if (type === "image" || type === "video" || type === "voice") {
      metrics.mediaMessages += 1;
      metrics.mediaBytes += safeNumber(row.mediaSizeBytes);
    }
    if (type === "voice") {
      metrics.voiceMessages += 1;
      metrics.voiceDurationMs += safeNumber(row.mediaDurationMs);
    }
    if (row.cloudMediaDeletePending === true) metrics.pendingMediaCleanup += 1;
  }

  metrics.deliveryRatePercent = percent(
    metrics.deliveredMessages,
    metrics.sampledMessages,
  );
  metrics.seenRatePercent = percent(metrics.seenMessages, metrics.sampledMessages);
  return metrics;
}

module.exports = { MESSAGE_TYPES, buildMessagingHealthMetrics, percent };
