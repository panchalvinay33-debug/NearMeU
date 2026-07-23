"use strict";

const RECENT_AUTH_WINDOW_SECONDS = 5 * 60;
const FUTURE_CLOCK_SKEW_SECONDS = 60;

function authenticationAgeSeconds(auth, nowMs = Date.now()) {
  const rawAuthTime = auth && auth.token ? auth.token.auth_time : null;
  const authTime = Number(rawAuthTime);
  if (!Number.isFinite(authTime) || authTime <= 0) return null;

  const nowSeconds = Math.floor(nowMs / 1000);
  return nowSeconds - Math.floor(authTime);
}

function isRecentAuthentication(
  auth,
  nowMs = Date.now(),
  maxAgeSeconds = RECENT_AUTH_WINDOW_SECONDS,
) {
  const age = authenticationAgeSeconds(auth, nowMs);
  if (age === null) return false;
  return age >= -FUTURE_CLOCK_SKEW_SECONDS && age <= maxAgeSeconds;
}

function accountDeletionMarker(uid) {
  const safeUid = typeof uid === "string" ? uid.trim() : "";
  if (!safeUid) throw new TypeError("A user id is required.");
  return `deleted:${safeUid}`;
}

module.exports = {
  FUTURE_CLOCK_SKEW_SECONDS,
  RECENT_AUTH_WINDOW_SECONDS,
  accountDeletionMarker,
  authenticationAgeSeconds,
  isRecentAuthentication,
};
