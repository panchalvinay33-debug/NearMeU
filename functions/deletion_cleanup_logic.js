"use strict";

function storageObjectPathFromUrl(value) {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed) return null;

  if (trimmed.startsWith("gs://")) {
    const withoutScheme = trimmed.slice("gs://".length);
    const separator = withoutScheme.indexOf("/");
    if (separator < 0 || separator === withoutScheme.length - 1) return null;
    return decodeURIComponent(withoutScheme.slice(separator + 1));
  }

  let parsed;
  try {
    parsed = new URL(trimmed);
  } catch (_) {
    return null;
  }

  if (parsed.hostname === "firebasestorage.googleapis.com") {
    const match = parsed.pathname.match(/^\/v0\/b\/[^/]+\/o\/(.+)$/);
    if (!match) return null;
    try {
      return decodeURIComponent(match[1]);
    } catch (_) {
      return null;
    }
  }

  if (parsed.hostname === "storage.googleapis.com") {
    const parts = parsed.pathname.split("/").filter(Boolean);
    if (parts.length < 2) return null;
    try {
      return decodeURIComponent(parts.slice(1).join("/"));
    } catch (_) {
      return null;
    }
  }

  return null;
}

module.exports = {
  storageObjectPathFromUrl,
};
