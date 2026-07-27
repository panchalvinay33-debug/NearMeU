# NearMeU — Pre-Test Readiness Gate

This document defines everything that must be completed **before two-device acceptance testing begins**.

## Source-controlled work — complete

- Non-calling V1 source is merged to `main`.
- Flutter formatting, analyze, tests and debug APK build are enforced by GitHub Actions.
- Cloud Functions tests and secure bootstrap loading are enforced.
- Firestore and Storage emulator rules tests are enforced.
- Firestore indexes, Storage rules and Cloud Functions are versioned in the repository.
- Android production builds refuse debug/unsigned signing.
- Final architecture, roadmap, backup/recovery plan and project-state manifest are versioned.
- Guarded scripts exist for readiness checks and production Firebase deployment.

## One-command local preflight

From the repository root on Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\tooling\pre_test_readiness.ps1
```

For JSON output:

```powershell
powershell -ExecutionPolicy Bypass -File .\tooling\pre_test_readiness.ps1 -Json
```

The checker verifies local tooling, required files, Firebase project mapping and accidental credential tracking. Release signing and final legal URLs are reported separately because they are required for Play submission, not for initial device acceptance testing.

## Guarded Firebase deployment

Preview the exact deployment without changing production:

```powershell
powershell -ExecutionPolicy Bypass -File .\tooling\deploy_firebase_production.ps1
```

Apply only after the owner confirms the production Firebase project, Blaze billing, budget alerts and backup status:

```powershell
powershell -ExecutionPolicy Bypass -File .\tooling\deploy_firebase_production.ps1 -Apply
```

The script:

1. Runs the readiness checker.
2. Refuses to continue when Firebase CLI is not using `nearmeu-e82c7`.
3. Requires typing the exact project ID.
4. Deploys Firestore rules and indexes.
5. Deploys Storage rules.
6. Deploys Cloud Functions.
7. Stores the versioned project-state manifest in Firestore.
8. Stops immediately when any stage fails.

## Owner-controlled prerequisites

These cannot be manufactured or guessed by source code:

- Firebase account with permission to deploy `nearmeu-e82c7`.
- Blaze billing enabled for Cloud Functions where required.
- Billing budget alerts configured in Google Cloud/Firebase.
- A confirmed backup/export location with appropriate IAM and retention.
- Registered App Check debug tokens for test APKs.
- Release signing key and private passwords, kept outside Git.
- Monitored support email.
- Stable public Privacy Policy URL.
- Stable public account-deletion URL.
- Play Console developer account and declarations.

## Pre-test deployment acceptance criteria

Testing may start only when:

- The latest `main` quality gate is green.
- The Firebase deployment script completes without error.
- Firestore rules, indexes, Storage rules and Functions show the expected deployed versions.
- Project-state manifest exists in Firestore.
- Two test accounts can authenticate without App Check rejection.
- Debug APK SHA fingerprints/debug tokens are registered where required.
- Push notification permissions can be granted on both phones.
- A database backup/export has been created or a documented restore point exists.

## App Check safety rule

Do **not** enable strict production App Check enforcement before the exact physical-test APK/device registration is verified. First observe metrics and validate trusted test traffic, then enforce per product following `docs/FIREBASE_APP_CHECK_DEPLOYMENT.md`.

## What remains after this gate

After this gate passes, the next phase is physical two-device acceptance testing. Play Store signing, final public legal URLs, store graphics, Data Safety declarations and Closed Testing follow after the core device flows are proven.
