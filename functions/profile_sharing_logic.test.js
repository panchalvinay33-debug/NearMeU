"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  buildShareUrl,
  createPublicProfileId,
  isValidPublicProfileId,
  profileIsShareable,
  safeSharedProfile,
} = require("./profile_sharing_logic");

test("public profile ids are opaque and URL safe", () => {
  const first = createPublicProfileId();
  const second = createPublicProfileId();
  assert.equal(isValidPublicProfileId(first), true);
  assert.equal(isValidPublicProfileId(second), true);
  assert.notEqual(first, second);
  assert.equal(buildShareUrl(first), `https://nearmeu-e82c7.web.app/p/${first}`);
});

test("invalid public ids are rejected", () => {
  for (const value of ["", "abc", "contains/slash", "contains space", null]) {
    assert.equal(isValidPublicProfileId(value), false);
  }
});

test("suspended or missing profiles are not shareable", () => {
  assert.equal(profileIsShareable(null), false);
  assert.equal(profileIsShareable({ nickname: "", isSuspended: false }), false);
  assert.equal(profileIsShareable({ nickname: "A", isSuspended: true }), false);
  assert.equal(profileIsShareable({ nickname: "A", isSuspended: false }), true);
});

test("safe shared profile excludes private identity and exact location", () => {
  const profile = safeSharedProfile(
    {
      nickname: "Test",
      gender: "Male",
      lookingFor: "Female",
      age: 25,
      state: "MP",
      country: "India",
      photoUrl: "https://example.test/photo.jpg",
      email: "secret@example.test",
      exactLatitude: 22.1,
      exactLongitude: 74.2,
      isSuspended: false,
      privacyVersion: 1,
    },
    "internal-uid",
  );

  assert.equal(profile.uid, "internal-uid");
  assert.equal(profile.nickname, "Test");
  assert.equal(Object.hasOwn(profile, "email"), false);
  assert.equal(Object.hasOwn(profile, "exactLatitude"), false);
  assert.equal(Object.hasOwn(profile, "exactLongitude"), false);
});
