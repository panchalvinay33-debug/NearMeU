"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  chatDocumentKey,
  mergeChatDocuments,
  shouldHidePreviewThroughClear,
  shouldScanLegacyChats,
} = require("./trusted_read_logic");

function document(path, source) {
  return { ref: { path }, source };
}

test("mixed current and legacy chat documents are combined without duplicates", () => {
  const current = document("chats/current", "current");
  const duplicateLegacy = document("chats/current", "legacy-duplicate");
  const oldChat = document("chats/old", "legacy");

  const result = mergeChatDocuments({
    normalDocuments: [current],
    legacyDocuments: [duplicateLegacy, oldChat],
    maximumDocuments: 100,
  });

  assert.deepEqual(result, [current, oldChat]);
});

test("normal chat documents remain authoritative when legacy scans overlap", () => {
  const current = document("chats/shared", "current");
  const legacy = document("chats/shared", "legacy");
  const [result] = mergeChatDocuments({
    normalDocuments: [current],
    legacyDocuments: [legacy],
    maximumDocuments: 100,
  });

  assert.equal(result.source, "current");
});

test("legacy scans continue while the normal inbox is below its preview cap", () => {
  assert.equal(shouldScanLegacyChats(0, 100), true);
  assert.equal(shouldScanLegacyChats(15, 100), true);
  assert.equal(shouldScanLegacyChats(99, 100), true);
  assert.equal(shouldScanLegacyChats(100, 100), false);
});

test("merge respects the document inspection ceiling", () => {
  const result = mergeChatDocuments({
    normalDocuments: [document("chats/a", "current")],
    legacyDocuments: [
      document("chats/b", "legacy"),
      document("chats/c", "legacy"),
    ],
    maximumDocuments: 2,
  });
  assert.deepEqual(result.map(chatDocumentKey), ["chats/a", "chats/b"]);
});

test("clear cutoff hides previews at or before the clear time", () => {
  assert.equal(shouldHidePreviewThroughClear(1000, 1000), true);
  assert.equal(shouldHidePreviewThroughClear(999, 1000), true);
  assert.equal(shouldHidePreviewThroughClear(null, 1000), true);
});

test("messages after a clear remain eligible for the chat preview", () => {
  assert.equal(shouldHidePreviewThroughClear(1001, 1000), false);
  assert.equal(shouldHidePreviewThroughClear(1001, null), false);
});
