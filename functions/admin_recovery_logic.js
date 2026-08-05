"use strict";

function percent(part, total) {
  if (!Number.isFinite(part) || !Number.isFinite(total) || total <= 0) return 0;
  return Math.round((part / total) * 10000) / 100;
}

function buildRecoveryHealthMetrics(input) {
  const safe = input && typeof input === "object" ? input : {};
  const deliveryActive = Number(safe.deliveryActive || 0);
  const deliveryExpiredBacklog = Number(safe.deliveryExpiredBacklog || 0);
  const deliveryExpiring24h = Number(safe.deliveryExpiring24h || 0);
  const premiumRecoveryUsers = Number(safe.premiumRecoveryUsers || 0);
  const premiumRecoveryActive = Number(safe.premiumRecoveryActive || 0);
  const premiumRecoveryExpiredBacklog = Number(safe.premiumRecoveryExpiredBacklog || 0);
  const premiumRecoveryExpiring7d = Number(safe.premiumRecoveryExpiring7d || 0);

  return {
    delivery: {
      activeStampedMessages: deliveryActive,
      expiredBacklog: deliveryExpiredBacklog,
      expiringWithin24h: deliveryExpiring24h,
      expiredBacklogRatePct: percent(
        deliveryExpiredBacklog,
        deliveryActive + deliveryExpiredBacklog,
      ),
    },
    premiumRecovery: {
      userRecords: premiumRecoveryUsers,
      activeRetainedMessages: premiumRecoveryActive,
      expiredBacklog: premiumRecoveryExpiredBacklog,
      expiringWithin7d: premiumRecoveryExpiring7d,
      expiredBacklogRatePct: percent(
        premiumRecoveryExpiredBacklog,
        premiumRecoveryActive + premiumRecoveryExpiredBacklog,
      ),
    },
  };
}

module.exports = { buildRecoveryHealthMetrics, percent };
