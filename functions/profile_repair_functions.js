"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const REGION = "asia-south1";
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

function requireUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function cleanString(value, maxLength, fallback = "") {
  if (typeof value !== "string") return fallback;
  const trimmed = value.trim();
  return trimmed.length <= maxLength ? trimmed : trimmed.slice(0, maxLength);
}

function allowedChoice(value, allowed, fallback = "") {
  return typeof value === "string" && allowed.has(value) ? value : fallback;
}

function safeAge(value) {
  const numeric = Number.isFinite(value) ? Math.trunc(value) : 18;
  return Math.min(99, Math.max(18, numeric));
}

function safeCoordinate(value, min, max) {
  return typeof value === "number" && Number.isFinite(value) && value >= min && value <= max
    ? value
    : null;
}

function safeTimestamp(value) {
  return value instanceof Timestamp ? value : FieldValue.serverTimestamp();
}

function validDiscoveryCells(value, locationCell) {
  if (!Array.isArray(value) || value.length === 0 || value.length > 9) return [];
  const cells = value.filter((cell) => typeof cell === "string" && cell.length > 0 && cell.length <= 32);
  if (cells.length !== value.length) return [];
  if (locationCell && !cells.includes(locationCell)) return [];
  return cells;
}

exports.repairMyPublicProfile = onCall({ region: REGION }, async (request) => {
  const uid = requireUid(request);
  const userRef = db.collection("users").doc(uid);
  const privateRef = db.collection("privateProfiles").doc(uid);
  const snapshot = await userRef.get();
  if (!snapshot.exists) {
    throw new HttpsError("failed-precondition", "User profile does not exist.");
  }

  const data = snapshot.data() || {};
  const legacyLatitude = safeCoordinate(data.latitude, -90, 90);
  const legacyLongitude = safeCoordinate(data.longitude, -180, 180);
  const approxLatitude = safeCoordinate(data.approxLatitude, -90, 90);
  const approxLongitude = safeCoordinate(data.approxLongitude, -180, 180);
  const latitude = approxLatitude ?? legacyLatitude;
  const longitude = approxLongitude ?? legacyLongitude;

  let locationCell = typeof data.locationCell === "string" && data.locationCell.length > 0 && data.locationCell.length <= 32
    ? data.locationCell
    : null;
  let discoveryCells = validDiscoveryCells(data.discoveryCells, locationCell);
  if (latitude === null || longitude === null || discoveryCells.length === 0) {
    // Never invent a discovery cell on the server. A subsequent successful
    // device location refresh will repopulate the rounded location safely.
    locationCell = null;
    discoveryCells = [];
  }

  const publicReplacement = {
    uid,
    nickname: cleanString(data.nickname, 30, "User") || "User",
    gender: allowedChoice(data.gender, new Set(["Male", "Female", "Other", "Both", ""])),
    lookingFor: allowedChoice(data.lookingFor, new Set(["Male", "Female", "Both", ""])),
    createdAt: safeTimestamp(data.createdAt),
    approxLatitude: latitude,
    approxLongitude: longitude,
    locationCell,
    discoveryCells,
    state: data.state == null ? null : cleanString(data.state, 80),
    country: data.country == null ? null : cleanString(data.country, 80),
    photoUrl: data.photoUrl == null ? null : cleanString(data.photoUrl, 2048),
    age: safeAge(data.age),
    lastSeen: data.lastSeen instanceof Timestamp ? data.lastSeen : null,
    isOnline: data.isOnline === true,
    isAdmin: data.isAdmin === true,
    isSuspended: data.isSuspended === true,
    privacyVersion: 1,
  };

  const batch = db.batch();
  batch.set(userRef, publicReplacement);

  const hasLegacyPrivateData = [
    "email",
    "latitude",
    "longitude",
    "city",
    "messageNotificationsEnabled",
    "nearbyAlertsEnabled",
  ].some((key) => Object.prototype.hasOwnProperty.call(data, key));

  if (hasLegacyPrivateData) {
    const privatePatch = {
      privacyVersion: 1,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (typeof data.email === "string") privatePatch.email = cleanString(data.email, 320);
    if (legacyLatitude !== null && legacyLongitude !== null) {
      privatePatch.exactLatitude = legacyLatitude;
      privatePatch.exactLongitude = legacyLongitude;
    }
    if (typeof data.city === "string") privatePatch.city = cleanString(data.city, 80);
    if (typeof data.messageNotificationsEnabled === "boolean") {
      privatePatch.messageNotificationsEnabled = data.messageNotificationsEnabled;
    }
    if (typeof data.nearbyAlertsEnabled === "boolean") {
      privatePatch.nearbyAlertsEnabled = data.nearbyAlertsEnabled;
    }
    batch.set(privateRef, privatePatch, { merge: true });
  }

  await batch.commit();
  return { repaired: true };
});
