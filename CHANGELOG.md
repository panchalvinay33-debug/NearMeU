# Changelog

## Unreleased

### Production readiness
- Enforced NearMeU as an adults-only (18+) experience across app validation, user defaults, profile completion, nearby discovery, and Firestore rules.
- Hardened Firestore user and report validation to reject malformed profile data, underage users, invalid locations, oversized strings, invalid notification preferences, and invalid reports.
- Improved account deletion safety by preventing duplicate delete taps and showing a user-friendly retry message when reauthentication or cleanup fails.
- Added retry-safe notification preference handling with UI rollback and clear messaging on network or permission failures.
- Tuned nearby discovery to query adult, non-suspended users only and to cap reads with a production page size.

### Documentation
- Added Play Store release readiness documentation and a manual release checklist.
