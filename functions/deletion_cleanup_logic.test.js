"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const { storageObjectPathFromUrl } = require("./deletion_cleanup_logic");

test("extracts an object path from a Firebase download URL", () => {
  assert.equal(
    storageObjectPathFromUrl(
      "https://firebasestorage.googleapis.com/v0/b/nearmeu-e82c7.firebasestorage.app/o/profile_photos%2Falice.jpg?alt=media&token=test",
    ),
    "profile_photos/alice.jpg",
  );
});

test("extracts an object path from a gs URL", () => {
  assert.equal(
    storageObjectPathFromUrl("gs://nearmeu-e82c7.firebasestorage.app/users/alice/photo.jpg"),
    "users/alice/photo.jpg",
  );
});

test("extracts an object path from a Google Storage URL", () => {
  assert.equal(
    storageObjectPathFromUrl(
      "https://storage.googleapis.com/nearmeu-e82c7.firebasestorage.app/profile_photos/alice.jpg",
    ),
    "profile_photos/alice.jpg",
  );
});

test("rejects unsupported and malformed URLs", () => {
  assert.equal(storageObjectPathFromUrl(""), null);
  assert.equal(storageObjectPathFromUrl("not-a-url"), null);
  assert.equal(storageObjectPathFromUrl("https://example.com/photo.jpg"), null);
  assert.equal(storageObjectPathFromUrl("gs://bucket-only"), null);
});
