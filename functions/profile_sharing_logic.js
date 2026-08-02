"use strict";

const crypto = require("crypto");

const PUBLIC_ID_PATTERN = /^[A-Za-z0-9_-]{20,64}$/;

function createPublicProfileId() {
  return crypto.randomBytes(18).toString("base64url");
}

function isValidPublicProfileId(value) {
  return typeof value === "string" && PUBLIC_ID_PATTERN.test(value);
}

function profileIsShareable(userData) {
  return Boolean(
    userData &&
      userData.isSuspended !== true &&
      typeof userData.nickname === "string" &&
      userData.nickname.trim().length > 0,
  );
}

function safeSharedProfile(userData, uid) {
  if (!profileIsShareable(userData)) return null;
  return {
    uid,
    nickname: userData.nickname || "",
    gender: userData.gender || "",
    lookingFor: userData.lookingFor || "",
    photoUrl: typeof userData.photoUrl === "string" ? userData.photoUrl : null,
    age: Number.isInteger(userData.age) ? userData.age : null,
    state: typeof userData.state === "string" ? userData.state : null,
    country: typeof userData.country === "string" ? userData.country : null,
    privacyVersion: Number.isInteger(userData.privacyVersion)
      ? userData.privacyVersion
      : 0,
  };
}

function buildShareUrl(publicId) {
  if (!isValidPublicProfileId(publicId)) {
    throw new Error("invalid-public-profile-id");
  }
  return `https://nearmeu-e82c7.web.app/p/${publicId}`;
}

module.exports = {
  PUBLIC_ID_PATTERN,
  buildShareUrl,
  createPublicProfileId,
  isValidPublicProfileId,
  profileIsShareable,
  safeSharedProfile,
};
