"use strict";

function normalizeCount(value) {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.trunc(value));
}

function roundOne(value) {
  return Math.round(value * 10) / 10;
}

function percent(part, total) {
  if (total <= 0) return 0;
  return roundOne((part / total) * 100);
}

function buildBusinessMetrics(raw = {}) {
  const totalUsers = normalizeCount(raw.totalUsers);
  const onlineUsers = normalizeCount(raw.onlineUsers);
  const suspendedUsers = normalizeCount(raw.suspendedUsers);
  const newUsers24h = normalizeCount(raw.newUsers24h);
  const newUsers7d = normalizeCount(raw.newUsers7d);
  const newUsers30d = normalizeCount(raw.newUsers30d);
  const premiumRecords = normalizeCount(raw.premiumRecords);
  const googlePlayMarkedActive = normalizeCount(raw.googlePlayMarkedActive);
  const adminMarkedActive = normalizeCount(raw.adminMarkedActive);

  const avgDaily7d = roundOne(newUsers7d / 7);
  const avgDaily30d = roundOne(newUsers30d / 30);
  const sevenDayVsThirtyDayPacePct = avgDaily30d > 0
    ? roundOne((avgDaily7d / avgDaily30d) * 100)
    : 0;

  return {
    users: {
      total: totalUsers,
      onlineMarked: onlineUsers,
      suspended: suspendedUsers,
      new24h: newUsers24h,
      new7d: newUsers7d,
      new30d: newUsers30d,
    },
    premium: {
      entitlementRecords: premiumRecords,
      googlePlayMarkedActive,
      adminMarkedActive,
    },
    rates: {
      onlineSharePct: percent(onlineUsers, totalUsers),
      suspendedSharePct: percent(suspendedUsers, totalUsers),
      avgDailyNewUsers7d: avgDaily7d,
      avgDailyNewUsers30d: avgDaily30d,
      sevenDayVsThirtyDayPacePct,
    },
  };
}

module.exports = {
  buildBusinessMetrics,
  normalizeCount,
  percent,
  roundOne,
};
