"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

const db = admin.firestore();
const REGION = "asia-south1";
const POLICY_REF = db.collection("appConfig").doc("android");

function requireAdmin(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
  return db.collection("users").doc(uid).get().then((snapshot) => {
    if (!snapshot.exists || snapshot.get("isAdmin") !== true) {
      throw new HttpsError("permission-denied", "Administrator access is required.");
    }
    return uid;
  });
}

function safePositiveInteger(value, fallback) {
  return Number.isInteger(value) && value > 0 ? value : fallback;
}

function safeString(value, fallback = "") {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

exports.getAndroidAppVersionPolicy = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async () => {
    const snapshot = await POLICY_REF.get();
    const data = snapshot.exists ? snapshot.data() || {} : {};

    return {
      latestVersionCode: safePositiveInteger(data.latestVersionCode, 1),
      latestVersionName: safeString(data.latestVersionName, "1.0.0"),
      minimumSupportedVersionCode: safePositiveInteger(
        data.minimumSupportedVersionCode,
        1,
      ),
      updateUrl: safeString(data.updateUrl),
      message: safeString(
        data.message,
        "A newer version of NearMeU is required to continue.",
      ),
      maintenanceMode: data.maintenanceMode === true,
      updatedAt: data.updatedAt || null,
    };
  },
);

exports.setAndroidAppVersionPolicy = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const adminId = await requireAdmin(request);
    const input = request.data || {};
    const latestVersionCode = safePositiveInteger(input.latestVersionCode, 0);
    const minimumSupportedVersionCode = safePositiveInteger(
      input.minimumSupportedVersionCode,
      0,
    );
    const latestVersionName = safeString(input.latestVersionName);
    const updateUrl = safeString(input.updateUrl);
    const message = safeString(
      input.message,
      "A newer version of NearMeU is required to continue.",
    );

    if (!latestVersionCode || !minimumSupportedVersionCode) {
      throw new HttpsError("invalid-argument", "Version codes must be positive integers.");
    }
    if (minimumSupportedVersionCode > latestVersionCode) {
      throw new HttpsError(
        "invalid-argument",
        "Minimum supported version cannot exceed the latest version.",
      );
    }
    if (!latestVersionName || latestVersionName.length > 40) {
      throw new HttpsError("invalid-argument", "Latest version name is invalid.");
    }
    if (!/^https:\/\//i.test(updateUrl) || updateUrl.length > 2048) {
      throw new HttpsError("invalid-argument", "A valid HTTPS update URL is required.");
    }
    if (message.length > 500) {
      throw new HttpsError("invalid-argument", "Update message is too long.");
    }

    await POLICY_REF.set(
      {
        latestVersionCode,
        latestVersionName,
        minimumSupportedVersionCode,
        updateUrl,
        message,
        maintenanceMode: input.maintenanceMode === true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedByAdminId: adminId,
      },
      { merge: true },
    );

    return { success: true };
  },
);
