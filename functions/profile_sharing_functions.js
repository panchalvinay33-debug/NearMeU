"use strict";

const admin = require("firebase-admin");
const functionsV1 = require("firebase-functions/v1");
const { HttpsError, onCall, onRequest } = require("firebase-functions/v2/https");

const {
  buildShareUrl,
  createPublicProfileId,
  isValidPublicProfileId,
  profileIsShareable,
  safeSharedProfile,
} = require("./profile_sharing_logic");

const REGION = "asia-south1";
const db = admin.firestore();

function requireAuthenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return uid;
}

function ownerShareRef(uid) {
  return db.collection("profileShareOwners").doc(uid);
}

function publicShareRef(publicId) {
  return db.collection("profileShareLinks").doc(publicId);
}

async function requireActiveProfile(uid) {
  const user = await db.collection("users").doc(uid).get();
  if (!user.exists || !profileIsShareable(user.data())) {
    throw new HttpsError("failed-precondition", "Profile sharing is unavailable.");
  }
  return user;
}

async function blockedEitherWay(viewerUid, targetUid) {
  if (!viewerUid || viewerUid === targetUid) return false;
  const [blockedByViewer, blockedByTarget] = await Promise.all([
    db.collection("users").doc(viewerUid).collection("blocks").doc(targetUid).get(),
    db.collection("users").doc(targetUid).collection("blocks").doc(viewerUid).get(),
  ]);
  return blockedByViewer.exists || blockedByTarget.exists;
}

async function createFreshShareLink(uid) {
  await requireActiveProfile(uid);

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const publicId = createPublicProfileId();
    const publicRef = publicShareRef(publicId);
    const ownerRef = ownerShareRef(uid);
    try {
      await db.runTransaction(async (transaction) => {
        const existing = await transaction.get(publicRef);
        if (existing.exists) throw new Error("public-id-collision");
        transaction.set(publicRef, {
          ownerUid: uid,
          enabled: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(ownerRef, {
          publicId,
          enabled: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      return { publicId, enabled: true, url: buildShareUrl(publicId) };
    } catch (error) {
      if (error && error.message === "public-id-collision") continue;
      throw error;
    }
  }
  throw new HttpsError("resource-exhausted", "Could not create a share link.");
}

async function purgeProfileSharingForUid(uid) {
  const owner = await ownerShareRef(uid).get();
  const publicId = owner.exists ? owner.get("publicId") : null;
  const batch = db.batch();
  batch.delete(ownerShareRef(uid));
  if (isValidPublicProfileId(publicId)) batch.delete(publicShareRef(publicId));
  await batch.commit();
}

exports.getMyProfileShareLink = onCall({ region: REGION }, async (request) => {
  const uid = requireAuthenticatedUid(request);
  await requireActiveProfile(uid);
  const owner = await ownerShareRef(uid).get();
  if (!owner.exists || !isValidPublicProfileId(owner.get("publicId"))) {
    return createFreshShareLink(uid);
  }
  const publicId = owner.get("publicId");
  const publicLink = await publicShareRef(publicId).get();
  const enabled = owner.get("enabled") === true && publicLink.exists && publicLink.get("enabled") === true;
  return { publicId, enabled, url: buildShareUrl(publicId) };
});

exports.setMyProfileSharingEnabled = onCall({ region: REGION }, async (request) => {
  const uid = requireAuthenticatedUid(request);
  await requireActiveProfile(uid);
  const enabled = request.data && request.data.enabled === true;
  const owner = await ownerShareRef(uid).get();
  if (!owner.exists || !isValidPublicProfileId(owner.get("publicId"))) {
    if (!enabled) return { enabled: false, url: null };
    return createFreshShareLink(uid);
  }
  const publicId = owner.get("publicId");
  const batch = db.batch();
  batch.set(ownerShareRef(uid), {
    enabled,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(publicShareRef(publicId), {
    ownerUid: uid,
    enabled,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  await batch.commit();
  return { publicId, enabled, url: buildShareUrl(publicId) };
});

exports.rotateMyProfileShareLink = onCall({ region: REGION }, async (request) => {
  const uid = requireAuthenticatedUid(request);
  await requireActiveProfile(uid);
  const oldOwner = await ownerShareRef(uid).get();
  const oldPublicId = oldOwner.exists ? oldOwner.get("publicId") : null;
  const fresh = await createFreshShareLink(uid);
  if (isValidPublicProfileId(oldPublicId) && oldPublicId !== fresh.publicId) {
    await publicShareRef(oldPublicId).delete().catch(() => {});
  }
  return fresh;
});

exports.resolveSharedProfile = onCall({ region: REGION }, async (request) => {
  const viewerUid = requireAuthenticatedUid(request);
  const publicId = request.data && request.data.publicId;
  if (!isValidPublicProfileId(publicId)) {
    throw new HttpsError("invalid-argument", "Invalid shared profile link.");
  }
  const link = await publicShareRef(publicId).get();
  if (!link.exists || link.get("enabled") !== true) {
    throw new HttpsError("not-found", "Shared profile is unavailable.");
  }
  const targetUid = link.get("ownerUid");
  if (typeof targetUid !== "string" || !targetUid) {
    throw new HttpsError("not-found", "Shared profile is unavailable.");
  }
  if (await blockedEitherWay(viewerUid, targetUid)) {
    throw new HttpsError("not-found", "Shared profile is unavailable.");
  }
  const user = await db.collection("users").doc(targetUid).get();
  const profile = user.exists ? safeSharedProfile(user.data(), targetUid) : null;
  if (!profile) throw new HttpsError("not-found", "Shared profile is unavailable.");
  return { profile };
});

function escapeHtml(value) {
  return String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

exports.sharedProfilePreview = onRequest({ region: REGION }, async (request, response) => {
  response.set("Cache-Control", "private, max-age=60");
  const match = request.path.match(/\/p\/([A-Za-z0-9_-]{20,64})\/?$/);
  const publicId = match && match[1];
  if (!isValidPublicProfileId(publicId)) {
    response.status(404).send("Profile unavailable");
    return;
  }
  const link = await publicShareRef(publicId).get();
  const targetUid = link.exists && link.get("enabled") === true ? link.get("ownerUid") : null;
  const user = typeof targetUid === "string"
    ? await db.collection("users").doc(targetUid).get()
    : null;
  const profile = user && user.exists ? safeSharedProfile(user.data(), targetUid) : null;
  if (!profile) {
    response.status(404).send("Profile unavailable");
    return;
  }

  const name = escapeHtml(profile.nickname);
  const details = [profile.age, profile.gender, profile.state, profile.country]
    .filter((value) => value !== null && value !== "")
    .map(escapeHtml)
    .join(" · ");
  const deepLink = `nearmeu://profile/${publicId}`;
  const playUrl = "https://play.google.com/store/apps/details?id=com.nearmeu.nearmeu";
  response.status(200).type("html").send(`<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${name} on NearMeU</title><meta name="robots" content="noindex,nofollow">
<style>body{font-family:system-ui;background:#0b0b0b;color:#fff;margin:0;display:grid;min-height:100vh;place-items:center}.card{max-width:460px;margin:24px;padding:28px;border-radius:24px;background:#171717;text-align:center}.muted{color:#aaa}.btn{display:block;margin-top:14px;padding:14px 18px;border-radius:14px;text-decoration:none;background:#7c4dff;color:#fff}.secondary{background:#2a2a2a}</style></head>
<body><main class="card"><h1>${name}</h1><p class="muted">${details}</p><p>View this profile securely in NearMeU.</p><a class="btn" href="${deepLink}">Open in NearMeU</a><a class="btn secondary" href="${playUrl}">Get NearMeU</a><p class="muted">Private email, Firebase UID and exact location are not shown on this page.</p></main></body></html>`);
});

exports.purgeProfileSharingOnAuthDelete = functionsV1
  .region(REGION)
  .auth.user()
  .onDelete(async (user) => {
    await purgeProfileSharingForUid(user.uid);
  });
