# NearMeU Official Recoverable Base

## Purpose

This document is the single source of truth for recovering NearMeU to a known working test state. A Git commit alone is not a complete recovery point. The recoverable base includes source, signing identity, Firebase project compatibility, App Check test registration, build evidence, APK checksum, and physical-device acceptance.

## Official base status

- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Source of truth: `main`
- Recovery branch: `stable/official-recoverable-base`
- Build workflow: `.github/workflows/recovery-base-apk.yml`
- Test build type: permanently signed Flutter debug APK
- App Check provider for test APK: Firebase App Check debug provider
- Production App Check provider: Play Integrity; production rollout is a separate owner-approved action
- Production deployment and Play Store publication are not part of recovery
- Accepted runtime base SHA: `05c75107aa9c8a71e325d02dcbcca0d63d5b031f`
- Recovery artifact source head SHA: `65e37f6418e5f543062865ab35f06b070aed2d54`
- Recovery workflow merge ref SHA: `003ff1f5bb696cde9045d9f15214f09e0f6dc3ec`
- Accepted recovery APK SHA-256: `587cd1b328a1caeb659a0c5d0604609c5e6a381b61efc6d0acd9d3c2b1bde00c`
- Permanent signing certificate SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`
- Recovery artifact build time: `2026-07-31T08:54:02Z`

The exact official Git SHA, APK SHA-256, signing certificate fingerprints, build timestamp, test devices, and physical acceptance result must be recorded in the workflow artifact `recovery-manifest.txt` and in the acceptance section below whenever the base is promoted.

## Why the base is recoverable

A recovery is valid only when all of these match:

1. Source code from the official base SHA.
2. Permanent NearMeU Android signing key restored from protected GitHub secrets.
3. Google OAuth/Firebase Android fingerprints corresponding to that signing key.
4. Firebase project `nearmeu-e82c7` and Android application ID `com.nearmeu.nearmeu`.
5. App Check debug secret from the installed test app registered in the Firebase App Check allow-list.
6. Current compatible Firestore rules, Storage rules, indexes, and Cloud Functions already deployed in Firebase.
7. Recovery workflow analyze, tests, signing verification, APK build, checksum, and manifest all pass.
8. Physical-device acceptance passes login, Nearby, and chat send/receive.

No App Check debug secret, keystore, password, private key, or test-account credential may be committed to GitHub or written into this document.

## Fast recovery procedure

### 1. Restore source

```powershell
git fetch origin
git checkout main
git reset --hard origin/main
git clean -fd
```

For an immutable checkpoint, use the SHA recorded in the latest accepted recovery manifest:

```powershell
git checkout <RECOVERY_BASE_SHA>
```

### 2. Build the official recovery APK

Run GitHub Actions workflow **Build recoverable base APK** on `main`. It:

- restores the permanent NearMeU signing key from GitHub secrets;
- records SHA-1 and SHA-256 certificate fingerprints;
- runs Flutter analyze and tests;
- builds the permanently signed debug APK;
- verifies the APK certificate;
- produces APK checksum and recovery manifest;
- removes signing files from the runner.

### 3. Install without changing identity

Install the artifact APK. Do not use an unsigned/default-debug-key APK. The permanent signing identity is required for Google Sign-In and update compatibility.

```powershell
.\adb.exe install -r .\app-debug.apk
```

If Android reports a signature mismatch from an unrelated older build, uninstall once and reinstall. Uninstalling may generate a new App Check debug secret.

### 4. Register App Check test installation

Read the debug secret from the installed app:

```powershell
.\adb.exe shell "run-as com.nearmeu.nearmeu sh -c 'cat shared_prefs/com.google.firebase.appcheck.debug.store.*.xml'"
```

In Firebase Console:

`App Check → Apps → NearMeU Android → Manage debug tokens`

Register the current `DEBUG_SECRET`. Keep it private. Do not paste it into GitHub, documentation, source, build logs, or public chat.

After registration:

```powershell
.\adb.exe shell am force-stop com.nearmeu.nearmeu
.\adb.exe logcat -c
```

Open NearMeU again and allow a short propagation period if Firebase recently returned `Too many attempts`.

### 5. Physical acceptance gate

The base is accepted only after two adult test accounts/devices pass:

- Google Sign-In completes without developer-configuration errors.
- Nearby loads current users without App Check authentication errors.
- Text message sends and arrives in both directions.
- Existing conversation history loads.
- App restart preserves authenticated navigation and history.
- No `Unauthenticated`, App Check rejection loop, or database-open crash occurs.

Record the result below before moving the stable recovery branch.

## Current physical acceptance record

- Date: 2026-07-31
- Status: **accepted official recoverable test base**
- Accepted runtime base SHA: `05c75107aa9c8a71e325d02dcbcca0d63d5b031f`
- Stable branch: `stable/official-recoverable-base`
- APK SHA-256: `587cd1b328a1caeb659a0c5d0604609c5e6a381b61efc6d0acd9d3c2b1bde00c`
- Result: permanent-signed debug APK passed Google Sign-In, Nearby loading, existing history, and chat send/receive after the installed App Check debug secret was registered in Firebase.
- CI evidence: recoverable-base workflow run 2 and canonical quality-gate run 384 completed successfully.
- External dependency: the App Check debug secret remains installation-specific and is intentionally not stored in Git. Reinstall or clear-data may require registering the newly generated secret.
- Security action: any debug secret exposed outside the owner-controlled environment must be deleted or rotated after testing.

This record is final for the accepted runtime base. Later documentation-only commits do not change the accepted app runtime unless the stable recovery branch is explicitly promoted after another physical acceptance.

## Backup blueprint

Owner-controlled backups must include:

- permanent Android keystore in at least two encrypted locations;
- keystore alias and passwords in a password manager, separate from the keystore file;
- GitHub Actions signing secrets;
- Firebase project ownership and recovery access;
- Google Play Console ownership and Play App Signing records when enabled;
- latest accepted recovery APK, APK SHA-256, recovery manifest, and certificate report;
- current Firestore rules, Storage rules, indexes, Functions source and deployed-version record;
- this repository and official recovery SHA.

Never back up private secrets inside the repository.

## Branch and change-control policy

- `main` is the only current source of truth.
- `stable/official-recoverable-base` points to the last physically accepted recovery commit.
- New work starts from `main` on one short-lived feature/fix branch.
- No runtime/config change merges without tests and documentation review.
- The stable recovery branch moves only after CI plus physical-device acceptance.
- Temporary build branches and PRs are closed after use.
- Old divergent branches must be deleted or reset to the official base so they cannot be mistaken for supported recovery points.
- No production Firebase deploy, signing rotation, Play upload, or public rollout occurs without explicit owner approval.

## Roadmap from this base

### Phase 0 — protect the base

- Keep the permanent recovery workflow green.
- Preserve signing and Firebase ownership backups.
- Rotate any exposed App Check debug token.
- Keep the accepted SHA, APK checksum, certificate fingerprints, devices, and results current whenever a new base is promoted.

### Phase 1 — reliability fixes

Each item must be implemented separately from the base:

- receiver media persistence and retry;
- encrypted local database lifecycle stability;
- unread badge convergence;
- persistent bottom navigation state;
- authoritative delivery/read receipts;
- weak-network, restart, logout/login and account-switch behavior.

### Phase 2 — V1 completion

- two-device text/photo/video/voice/reply/unsend/delete validation;
- privacy/security rules audit;
- accessibility and lifecycle audit;
- standardized loading/empty/retry/error states;
- production release readiness.

### Phase 3 — controlled release

Separate explicit approval is required for Firebase production deploy, Play Internal Testing, closed testing, and production rollout.

## Incident rule

When a new change breaks the app:

1. Stop work on the failing branch.
2. Do not modify `main` or the stable recovery branch.
3. Install the last accepted recovery artifact and verify its checksum.
4. Register the installation's App Check debug secret if needed.
5. Confirm login, Nearby, and chat.
6. Fix the defect on a new branch based on `main`.
7. Promote a new base only after CI and physical acceptance.
