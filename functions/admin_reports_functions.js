"use strict";

const admin = require("firebase-admin");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { evaluateAdminAuthorization } = require("./admin_session_logic");
const {
  normalizeDecision,
  normalizeDecisionNote,
  normalizeReportId,
  normalizeReportStatus,
  safeReportProjection,
} = require("./admin_reports_logic");

const REGION = "asia-south1";
const RECENT_REPORT_SCAN_LIMIT = 100;
const RETURN_LIMIT = 50;
const db = admin.firestore();

function requireAdmin(request, permission) {
  const result = evaluateAdminAuthorization(request.auth, permission);
  if (!result.ok) {
    const message = result.code === "unauthenticated"
      ? "Authentication required."
      : "Admin authorization required.";
    throw new HttpsError(result.code, message);
  }
  return result.actor;
}

async function writeAudit(actor, action, details = {}) {
  await db.collection("adminAudit").add({
    actorUid: actor.uid,
    actorRole: actor.role,
    action,
    details,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAtIso: new Date().toISOString(),
  });
}

function safeUserSnapshot(uid, data) {
  const safe = data && typeof data === "object" ? data : {};
  return {
    uid,
    nickname: typeof safe.nickname === "string" ? safe.nickname : null,
    photoUrl: typeof safe.photoUrl === "string" ? safe.photoUrl : null,
    state: typeof safe.state === "string" ? safe.state : null,
    country: typeof safe.country === "string" ? safe.country : null,
    isSuspended: safe.isSuspended === true,
  };
}

async function readSafeUser(uid) {
  if (!uid) return null;
  const snapshot = await db.collection("users").doc(uid).get();
  return snapshot.exists ? safeUserSnapshot(uid, snapshot.data()) : { uid };
}

async function statusCount(status) {
  const result = await db.collection("reports")
    .where("status", "==", status)
    .count()
    .get();
  return result.data().count;
}

const listAdminReports = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "safety.review");
  const status = normalizeReportStatus(request.data && request.data.status);
  if (!status) {
    throw new HttpsError("invalid-argument", "Valid report status is required.");
  }

  const [snapshot, pendingCount, resolvedCount, dismissedCount] = await Promise.all([
    db.collection("reports")
      .orderBy("createdAt", "desc")
      .limit(RECENT_REPORT_SCAN_LIMIT)
      .get(),
    statusCount("pending"),
    statusCount("resolved"),
    statusCount("dismissed"),
  ]);

  const reports = snapshot.docs
    .map((doc) => safeReportProjection(doc.id, doc.data()))
    .filter((report) => status === "all" || report.status === status)
    .slice(0, RETURN_LIMIT);

  await writeAudit(actor, "safety.reports.list", {
    status,
    returned: reports.length,
  });

  return {
    status,
    counts: {
      pending: pendingCount,
      resolved: resolvedCount,
      dismissed: dismissedCount,
    },
    reports,
    limits: {
      recentScan: RECENT_REPORT_SCAN_LIMIT,
      returned: RETURN_LIMIT,
    },
  };
});

const getAdminReportDetail = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "safety.review");
  const reportId = normalizeReportId(request.data && request.data.reportId);
  if (!reportId) {
    throw new HttpsError("invalid-argument", "Valid reportId is required.");
  }

  const snapshot = await db.collection("reports").doc(reportId).get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Report not found.");
  }

  const report = safeReportProjection(reportId, snapshot.data());
  const [reporter, reportedUser] = await Promise.all([
    readSafeUser(report.reporterId),
    readSafeUser(report.reportedUserId),
  ]);

  await writeAudit(actor, "safety.report.view", {
    reportId,
    reportedUserId: report.reportedUserId,
  });

  return {
    report,
    reporter,
    reportedUser,
    contextPolicy: {
      unrestrictedChatAccess: false,
      exactLocationAccess: false,
      privateProfileAccess: false,
      messageContentIncluded: false,
    },
  };
});

const setAdminReportDecision = onCall({ region: REGION }, async (request) => {
  const actor = requireAdmin(request, "safety.review");
  const reportId = normalizeReportId(request.data && request.data.reportId);
  const decision = normalizeDecision(request.data && request.data.decision);
  const note = normalizeDecisionNote(request.data && request.data.note);
  if (!reportId || !decision || !note) {
    throw new HttpsError(
      "invalid-argument",
      "Valid reportId, decision and 4-500 character note are required.",
    );
  }

  const ref = db.collection("reports").doc(reportId);
  let beforeStatus = null;
  let reportedUserId = null;
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Report not found.");
    }
    const current = safeReportProjection(reportId, snapshot.data());
    beforeStatus = current.status;
    reportedUserId = current.reportedUserId;
    const now = admin.firestore.Timestamp.now();
    const update = {
      status: decision,
      reviewedBy: actor.uid,
      reviewedAt: now,
      moderation: {
        decision,
        note,
        actorUid: actor.uid,
        actorRole: actor.role,
        at: now,
      },
    };
    if (decision === "resolved") {
      update.resolvedBy = actor.uid;
      update.resolvedAt = now;
    } else if (decision === "pending") {
      update.resolvedBy = admin.firestore.FieldValue.delete();
      update.resolvedAt = admin.firestore.FieldValue.delete();
    }
    transaction.update(ref, update);
  });

  await writeAudit(actor, "safety.report.decision", {
    reportId,
    reportedUserId,
    beforeStatus,
    afterStatus: decision,
    note,
  });

  return {
    reportId,
    status: decision,
  };
});

module.exports = {
  getAdminReportDetail,
  listAdminReports,
  setAdminReportDecision,
};
