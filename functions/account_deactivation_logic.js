"use strict";

function isDeactivatedValue(value) {
  return value === true;
}

function isActiveAccountData(data) {
  return Boolean(data) && data.isSuspended !== true && data.isDeactivated !== true;
}

function chatPeerAvailability(data) {
  if (!data) {
    return {
      unavailable: true,
      deactivated: false,
      effectivelyOnlineAllowed: false,
    };
  }

  const deactivated = data.isDeactivated === true;
  return {
    unavailable: false,
    deactivated,
    effectivelyOnlineAllowed: !deactivated && data.isSuspended !== true,
  };
}

module.exports = {
  chatPeerAvailability,
  isActiveAccountData,
  isDeactivatedValue,
};
