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

function closedPublicProfile(uid, existing = {}, timestamp) {
  if (typeof uid !== "string" || !uid.trim()) {
    throw new TypeError("A user id is required.");
  }

  return {
    uid: uid.trim(),
    nickname: "Account unavailable",
    gender: "",
    lookingFor: "",
    createdAt: existing.createdAt || timestamp,
    approxLatitude: null,
    approxLongitude: null,
    locationCell: null,
    discoveryCells: [],
    state: null,
    country: null,
    photoUrl: null,
    age: Number.isInteger(existing.age) ? existing.age : 18,
    lastSeen: timestamp,
    isOnline: false,
    isAdmin: existing.isAdmin === true,
    isSuspended: existing.isSuspended === true,
    privacyVersion: Number.isInteger(existing.privacyVersion)
      ? existing.privacyVersion
      : 1,
    accountState: ACCOUNT_STATE_CLOSED,
    closedAt: timestamp,
  };
}

module.exports = {
  ACCOUNT_STATE_ACTIVE,
  ACCOUNT_STATE_CLOSED,
  accountState,
  closedPublicProfile,
  identityEmailKey,
  normalizeVerifiedEmail,
};
