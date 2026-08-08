"use strict";

const fs = require("node:fs");
const path = require("node:path");
const admin = require("firebase-admin");

const EXPECTED_PROJECT_ID = "nearmeu-e82c7";
const PRIVACY_VERSION = 1;
const APPLY_CONFIRMATION = "V1_PRIVATE_PROFILE_MIGRATION";
const LEGACY_PRIVATE_KEYS = [
  "email",
  "latitude",
  "longitude",
  "city",
  "blockedUsers",
  "messageNotificationsEnabled",
  "nearbyAlertsEnabled",
];

function parseArgs(argv) {
  const args = new Map();
  for (const value of argv.slice(2)) {
    if (!value.startsWith("--")) continue;
    const separator = value.indexOf("=");
    if (separator === -1) {
      args.set(value.slice(2), true);
    } else {
      args.set(value.slice(2, separator), value.slice(separator + 1));
    }
  }
  return args;
}

function isValidLatitude(value) {
  return typeof value === "number" && Number.isFinite(value) && value >= -90 && value <= 90;
}

function isValidLongitude(value) {
  return typeof value === "number" && Number.isFinite(value) && value >= -180 && value <= 180;
}

function nonEmptyString(value) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function safeBoolean(value, fallback) {
  return typeof value === "boolean" ? value : fallback;
}

function legacyKeysPresent(data) {
  return LEGACY_PRIVATE_KEYS.filter((key) => Object.prototype.hasOwnProperty.call(data, key));
}

function privatePatchFor({ publicData, privateData, authEmail, privateMissing }) {
  const patch = {
    privacyVersion: PRIVACY_VERSION,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const hasPrivate = (key) => Object.prototype.hasOwnProperty.call(privateData, key);

  if (privateMissing || !hasPrivate("email")) {
    patch.email = nonEmptyString(publicData.email) || nonEmptyString(authEmail) || "";
  }

  const legacyLatitude = isValidLatitude(publicData.latitude) ? publicData.latitude : null;
  const legacyLongitude = isValidLongitude(publicData.longitude) ? publicData.longitude : null;
  const hasLegacyExactPair = legacyLatitude !== null && legacyLongitude !== null;

  if (privateMissing || !hasPrivate("exactLatitude")) {
    patch.exactLatitude = hasLegacyExactPair ? legacyLatitude : null;
  }
  if (privateMissing || !hasPrivate("exactLongitude")) {
    patch.exactLongitude = hasLegacyExactPair ? legacyLongitude : null;
  }
  if (privateMissing || !hasPrivate("city")) {
    patch.city = nonEmptyString(publicData.city);
  }
  if (privateMissing || !hasPrivate("messageNotificationsEnabled")) {
    patch.messageNotificationsEnabled = safeBoolean(
      publicData.messageNotificationsEnabled,
      true,
    );
  }
  if (privateMissing || !hasPrivate("nearbyAlertsEnabled")) {
    patch.nearbyAlertsEnabled = safeBoolean(publicData.nearbyAlertsEnabled, false);
  }

  return patch;
}

async function getAuthEmail(uid) {
  try {
    const record = await admin.auth().getUser(uid);
    return record.email || null;
  } catch (error) {
    if (error && error.code === "auth/user-not-found") return null;
    throw error;
  }
}

async function writeLegacyBlocks(userRef, uid, blockedUsers) {
  const validIds = Array.isArray(blockedUsers)
    ? [...new Set(blockedUsers.filter((value) => typeof value === "string" && value && value !== uid))]
    : [];

  for (let start = 0; start < validIds.length; start += 400) {
    const batch = admin.firestore().batch();
    for (const blockedUid of validIds.slice(start, start + 400)) {
      batch.set(userRef.collection("blocks").doc(blockedUid), {
        blockerId: uid,
        blockedUserId: blockedUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    await batch.commit();
  }
}

async function main() {
  const args = parseArgs(process.argv);
  const apply = args.get("apply") === true;
  const confirmation = args.get("confirm");
  const backupPath = typeof args.get("backup") === "string" ? args.get("backup") : null;

  if (apply && confirmation !== APPLY_CONFIRMATION) {
    throw new Error(
      `Apply refused. Re-run with --apply --confirm=${APPLY_CONFIRMATION} and --backup=<absolute path>.`,
    );
  }
  if (apply && !backupPath) {
    throw new Error("Apply refused. A local --backup=<absolute path> is mandatory.");
  }

  admin.initializeApp({ projectId: EXPECTED_PROJECT_ID });
  const db = admin.firestore();

  const [usersSnapshot, privateSnapshot] = await Promise.all([
    db.collection("users").get(),
    db.collection("privateProfiles").get(),
  ]);

  const privateByUid = new Map(
    privateSnapshot.docs.map((document) => [document.id, document]),
  );
  const userIds = new Set(usersSnapshot.docs.map((document) => document.id));
  const orphanPrivateProfiles = privateSnapshot.docs
    .filter((document) => !userIds.has(document.id))
    .map((document) => document.id)
    .sort();

  const plans = [];
  for (const userDocument of usersSnapshot.docs) {
    const uid = userDocument.id;
    const publicData = userDocument.data() || {};
    const privateDocument = privateByUid.get(uid);
    const privateData = privateDocument ? privateDocument.data() || {} : {};
    const privateMissing = !privateDocument;
    const legacyKeys = legacyKeysPresent(publicData);
    const privateVersionCurrent = privateData.privacyVersion === PRIVACY_VERSION;
    const needsRepair = privateMissing || legacyKeys.length > 0 || !privateVersionCurrent;
    if (!needsRepair) continue;

    const authEmail = privateMissing || !Object.prototype.hasOwnProperty.call(privateData, "email")
      ? await getAuthEmail(uid)
      : null;

    plans.push({
      uid,
      publicData,
      privateData,
      privateMissing,
      legacyKeys,
      authEmail,
      privatePatch: privatePatchFor({
        publicData,
        privateData,
        authEmail,
        privateMissing,
      }),
    });
  }

  const report = {
    projectId: EXPECTED_PROJECT_ID,
    mode: apply ? "APPLY" : "DRY_RUN",
    usersFound: usersSnapshot.size,
    privateProfilesFound: privateSnapshot.size,
    usersNeedingRepair: plans.length,
    missingPrivateProfiles: plans.filter((plan) => plan.privateMissing).map((plan) => plan.uid),
    orphanPrivateProfiles,
    repairs: plans.map((plan) => ({
      uid: plan.uid,
      privateProfileMissing: plan.privateMissing,
      legacyPublicKeysToRemove: plan.legacyKeys,
      privateFieldsToBackfill: Object.keys(plan.privatePatch).filter(
        (key) => key !== "updatedAt",
      ),
      publicIdentityFieldsChanged: [],
    })),
  };

  console.log(JSON.stringify(report, null, 2));

  if (!apply) {
    console.log("\nDRY RUN ONLY. No Firestore documents were changed.");
    return;
  }

  const absoluteBackupPath = path.resolve(backupPath);
  fs.mkdirSync(path.dirname(absoluteBackupPath), { recursive: true });
  const backup = {
    projectId: EXPECTED_PROJECT_ID,
    createdAt: new Date().toISOString(),
    users: plans.map((plan) => ({
      uid: plan.uid,
      publicProfile: plan.publicData,
      privateProfileExisted: !plan.privateMissing,
      privateProfile: plan.privateData,
    })),
    orphanPrivateProfiles,
  };
  fs.writeFileSync(absoluteBackupPath, JSON.stringify(backup, null, 2), {
    encoding: "utf8",
    flag: "wx",
  });
  console.log(`\nBackup written before mutation: ${absoluteBackupPath}`);

  for (const plan of plans) {
    const userRef = db.collection("users").doc(plan.uid);
    const privateRef = db.collection("privateProfiles").doc(plan.uid);

    if (plan.legacyKeys.includes("blockedUsers")) {
      await writeLegacyBlocks(userRef, plan.uid, plan.publicData.blockedUsers);
    }

    const publicPatch = {
      privacyVersion: PRIVACY_VERSION,
    };
    for (const key of plan.legacyKeys) {
      publicPatch[key] = admin.firestore.FieldValue.delete();
    }

    const batch = db.batch();
    batch.set(privateRef, plan.privatePatch, { merge: true });
    batch.set(userRef, publicPatch, { merge: true });
    await batch.commit();
  }

  console.log(`\nAPPLY COMPLETE. Repaired ${plans.length} user profile pair(s).`);
  if (orphanPrivateProfiles.length) {
    console.log(
      `Orphan privateProfiles were reported but NOT deleted: ${orphanPrivateProfiles.join(", ")}`,
    );
  }
}

main().catch((error) => {
  console.error("V1 private-profile migration failed:", error);
  process.exitCode = 1;
});
