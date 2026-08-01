"use strict";

const crypto = require("crypto");

const ACCOUNT_STATE_ACTIVE = "active";
const ACCOUNT_STATE_CLOSED = "closed";

function normalizeVerifiedEmail(email) {
  if (typeof email !== "string") return "";
  return email.trim().toLowerCase();
}

function identityEmailKey(email) {
  const normalized = normalizeVerifiedEmail(email);
  if (!normalized) throw new TypeError("A verified email is required.");
  return crypto.createHash("sha256").update(normalized).digest("hex");
}

function accountState(data) {
  return data && data.accountState === ACCOUNT_STATE_CLOSED
    ? ACCOUNT_STATE_CLOSED
    : ACCOUNT_STATE_ACTIVE;
}

function closedLifecycleRecord(uid, existingUser = {}, timestamp) {
  const safeUid = typeof uid === "string" ? uid.trim() : "";
  if (!safeUid) throw new TypeError("A user id is required.");

  return {
    uid: safeUid,
    accountState: ACCOUNT_STATE_CLOSED,
    closedAt: timestamp,
    preservedCreatedAt: existingUser.createdAt || null,
    preservedIsAdmin: existingUser.isAdmin === true,
    preservedIsSuspended: existingUser.isSuspended === true,
  };
}

module.exports = {
  ACCOUNT_STATE_ACTIVE,
  ACCOUNT_STATE_CLOSED,
  accountState,
  closedLifecycleRecord,
  identityEmailKey,
  normalizeVerifiedEmail,
};
