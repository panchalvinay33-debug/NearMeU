"use strict";

function evaluateAdminAuthorization(auth, permission = null) {
  const uid = auth && auth.uid;
  if (!uid) {
    return { ok: false, code: "unauthenticated" };
  }

  const token = auth.token || {};
  const role = token.nearmeuAdminRole;
  const permissions = Array.isArray(token.nearmeuAdminPermissions)
    ? token.nearmeuAdminPermissions.filter((value) => typeof value === "string")
    : [];

  if (role !== "owner" && role !== "admin") {
    return { ok: false, code: "permission-denied" };
  }

  if (permission && role !== "owner" && !permissions.includes(permission)) {
    return { ok: false, code: "permission-denied" };
  }

  return {
    ok: true,
    actor: {
      uid,
      role,
      permissions,
    },
  };
}

module.exports = { evaluateAdminAuthorization };
