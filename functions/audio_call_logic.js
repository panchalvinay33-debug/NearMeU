"use strict";

const crypto = require("node:crypto");

const CALL_ID_PATTERN = /^[A-Za-z0-9_-]{20,64}$/;
const TERMINAL_STATUSES = new Set(["declined", "ended", "missed", "expired"]);

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

function isTerminalCallStatus(status) {
  return TERMINAL_STATUSES.has(status);
}

function safeDisplayName(value) {
  if (typeof value !== "string") return "NearMeU user";
  const normalized = value.trim().replace(/\s+/g, " ");
  if (!normalized) return "NearMeU user";
  return normalized.slice(0, 30);
}

function participantRole(call, uid) {
  if (!call || !uid) return null;
  if (call.callerUid === uid) return "caller";
  if (call.calleeUid === uid) return "callee";
  return null;
}

function pointerAvailable(pointer, nowMillis) {
  if (!pointer || typeof pointer !== "object") return true;
  const expiresAtMillis = Number(pointer.expiresAtMillis || 0);
  return !Number.isFinite(expiresAtMillis) || expiresAtMillis <= nowMillis;
}

module.exports = {
  agoraUidFromFirebaseUid,
  channelNameForCall,
  createCallId,
  isTerminalCallStatus,
  normalizeUid,
  participantRole,
  pointerAvailable,
  safeDisplayName,
  validCallId,
};
