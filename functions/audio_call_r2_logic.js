"use strict";

const crypto = require("node:crypto");

const CALL_ID_PATTERN = /^[A-Za-z0-9_-]{20,64}$/;
const ACTIVE_STATUSES = new Set(["ringing", "accepted"]);
const TERMINAL_STATUSES = new Set(["declined", "ended", "missed", "expired"]);
const ALL_STATUSES = new Set([...ACTIVE_STATUSES, ...TERMINAL_STATUSES]);

function normalizeUid(value) {
  return typeof value === "string" ? value.trim() : "";
}

function validCallId(value) {
  return typeof value === "string" && CALL_ID_PATTERN.test(value);
}

function createCallId() {
  return crypto.randomBytes(18).toString("base64url");
}

function channelNameForCall(callId) {
  if (!validCallId(callId)) throw new Error("invalid-call-id");
  return `nm_${callId}`;
}

function agoraUidFromFirebaseUid(uid) {
  const normalized = normalizeUid(uid);
  if (!normalized) throw new Error("invalid-user-id");
  const digest = crypto.createHash("sha256").update(normalized).digest();
  const value = digest.readUInt32BE(0);
  return value === 0 ? 1 : value;
}

function isKnownStatus(status) {
  return ALL_STATUSES.has(status);
}

function isTerminalStatus(status) {
  return TERMINAL_STATUSES.has(status);
}

function participantRole(call, uid) {
  const normalizedUid = normalizeUid(uid);
  if (!call || !normalizedUid) return null;
  if (call.callerUid === normalizedUid) return "caller";
  if (call.calleeUid === normalizedUid) return "callee";
  return null;
}

function canTransition({ status, actorRole, action }) {
  if (!isKnownStatus(status)) return false;
  if (isTerminalStatus(status)) return false;

  if (status === "ringing") {
    if (actorRole === "callee" && action === "accept") return true;
    if (actorRole === "callee" && action === "decline") return true;
    if (actorRole === "caller" && action === "end") return true;
    return false;
  }

  if (status === "accepted") {
    return (actorRole === "caller" || actorRole === "callee") && action === "end";
  }

  return false;
}

function nextStatus({ status, actorRole, action }) {
  if (!canTransition({ status, actorRole, action })) {
    throw new Error("invalid-call-transition");
  }
  if (action === "accept") return "accepted";
  if (action === "decline") return "declined";
  return "ended";
}

function pointerAvailable(pointer, nowMillis) {
  if (!pointer || typeof pointer !== "object") return true;
  const expiresAtMillis = Number(pointer.expiresAtMillis || 0);
  if (!Number.isFinite(expiresAtMillis) || expiresAtMillis <= 0) return false;
  return expiresAtMillis <= nowMillis;
}

function safeDisplayName(value) {
  if (typeof value !== "string") return "NearMeU user";
  const normalized = value.trim().replace(/\s+/g, " ");
  if (!normalized) return "NearMeU user";
  return normalized.slice(0, 30);
}

module.exports = {
  ACTIVE_STATUSES,
  TERMINAL_STATUSES,
  agoraUidFromFirebaseUid,
  canTransition,
  channelNameForCall,
  createCallId,
  isKnownStatus,
  isTerminalStatus,
  nextStatus,
  normalizeUid,
  participantRole,
  pointerAvailable,
  safeDisplayName,
  validCallId,
};
