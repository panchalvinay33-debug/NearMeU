# NearMeU Android Stability and Recovery Rulebook

Last updated: 2026-08-08

This document is authoritative for recovery, Android compatibility, stable-base promotion and future feature work.

## 1. Current recovery direction

- The recovery validation anchor is the original pre-calling Batch 08 merged runtime: `f83a6e92457f728f177dc062dcc9171c141a9217`.
- Recovery work happens on `recovery/original-batch08-android-stable`.
- Batch 08.1 is historical evidence only and is not a development base. Its changes must not be bulk-reapplied.
- Batch 09 audio calling is frozen and must not be merged or used as a base until the recovered Android-stable baseline passes all gates below.
- Samsung and Motorola are physical test devices, not product targets. NearMeU must use generic Android APIs and generic resilience rather than OEM-specific hacks.

## 2. Definition of a stable base

A runtime is not a stable base merely because CI is green or a feature works on one phone. A stable base requires all of the following:

1. Exact source commit recorded.
2. Scope frozen and reviewed.
3. Flutter analysis/tests pass.
4. Firebase Rules and Cloud Functions checks pass when applicable.
5. Permanently signed Android artifact exists.
6. Core regression matrix passes.
7. Physical tests pass on at least the current representative Samsung and Motorola devices.
8. Owner explicitly accepts the exact tested state.
9. GitHub recovery branch/tag/commit is recorded.
10. A complete PC recovery backup is created and verified.
11. Documentation and checksums are stored with the backup.
12. Restore procedure is proven before the next feature batch starts.

If any item is missing, the state is a candidate or test build, not a stable base.

## 3. Mandatory PC backup for every stable base

Every owner-accepted stable base must have an independent local recovery copy on the owner's PC in addition to GitHub and CI artifacts.

Canonical backup root:

`F:\NearMeU_Stable_Backups`

Recommended folder naming:

`F:\NearMeU_Stable_Backups\Base-<batch>-<yyyyMMdd>-<shortSHA>`

Example:

`F:\NearMeU_Stable_Backups\Base-08R-20260808-f83a6e9`

The folder must contain:

- `source\` — a complete clean working tree including `.git` metadata;
- `artifacts\` — the exact signed APK/AAB tested and accepted;
- `checksums\SHA256SUMS.txt` — hashes for all accepted artifacts and the source archive;
- `metadata\BASE_INFO.txt` — batch, branch, full commit SHA, version, package name, Firebase project, date and owner acceptance;
- `metadata\FIREBASE_STATE.txt` — deployed Functions/Rules/App Check state relevant to that base, without secret values;
- `metadata\PHYSICAL_TEST_RESULT.txt` — device/API/version and PASS/FAIL/deferred evidence;
- `restore\RESTORE_COMMANDS.ps1.txt` — exact restore commands;
- one compressed source archive, e.g. `NearMeU-Base-08R-<shortSHA>.zip`.

Secrets, private keystores and raw secret values must not be copied into ordinary source archives. Permanent signing material remains in its protected owner/CI location. The backup records the signing certificate fingerprint, not private key contents.

### PC backup acceptance gate

Before the next feature batch starts:

1. Confirm backup folder exists.
2. Confirm `.git`, `lib`, `android`, `functions`, Firebase rules/config and `pubspec.yaml` are present in `source`.
3. Confirm recorded commit matches `git rev-parse HEAD`.
4. Confirm ZIP SHA-256 and APK SHA-256 are recorded.
5. Extract the ZIP to a temporary folder and confirm Git can read the expected commit.
6. Do not delete the previous stable backup when promoting a newer one.

## 4. Recovery validation flow for the current project

### Phase A — Freeze

- No new calling/video/Admin features.
- No broad Firebase deploys.
- No changes to `main` for recovery experiments.
- Preserve current Batch 09 branch as reference only.

### Phase B — Original Batch 08 recovery anchor

Use exact commit:

`f83a6e92457f728f177dc062dcc9171c141a9217`

Recovery branch:

`recovery/original-batch08-android-stable`

Do not import Batch 08.1 wholesale.

### Phase C — Backend compatibility audit

Before blaming client source, compare the original Batch 08 assumptions with current Firebase state:

- Firebase project identity;
- Firebase Auth/Google sign-in configuration;
- App Check provider/enforcement;
- callable Functions and regions;
- Firestore Rules;
- Storage Rules;
- notification/FCM requirements;
- deployed functions added after Batch 08;
- backward compatibility for existing Batch 08 callables.

A current backend change must not silently force an accepted older client into registration, unauthenticated or broken-chat behavior.

### Phase D — Core Android regression matrix

The recovered baseline must pass, at minimum:

1. Fresh launch shows the intended Google sign-in entry path.
2. Existing Google account is recognized.
3. New account reaches profile creation only after authentication.
4. Existing profile is not treated as missing.
5. Nearby loads correctly with permission handling.
6. Presence online/offline is correct.
7. Text send/receive works.
8. Message/read state remains correct.
9. Photo send/receive works.
10. Video send/receive works.
11. Voice message works.
12. Clear Chat works and does not resurrect cleared history.
13. Delete for Me works.
14. Delete for Everyone/Unsend works.
15. Premium/recovery behavior from accepted earlier batches does not regress.
16. Notification receive/tap works.
17. Foreground/background/resume works.
18. Process kill/reopen works.
19. Wi-Fi works.
20. Mobile data works.
21. Wi-Fi/mobile switching degrades gracefully.
22. Weak/slow network uses bounded waits/failure states instead of hanging.
23. Logout/login works.
24. Device reboot/reopen works.

Any unexplained failure stops promotion.

## 5. Android compatibility doctrine

NearMeU is an Android app, not a Samsung app or Motorola app.

Allowed:

- documented Android SDK APIs;
- optional hardware declarations where a feature is optional;
- bounded timeouts;
- lifecycle-safe retry/reconnect;
- cache/fallback behavior that preserves correctness;
- runtime permission handling;
- graceful handling of missing Bluetooth/camera/microphone/location capabilities;
- testing across multiple API levels, RAM classes, network states and OEMs.

Not allowed without strong documented necessity:

- Samsung-only code paths;
- Motorola-only code paths;
- device-model allow/deny lists;
- indefinite waits introduced to mask OEM behavior;
- weakening authentication/App Check/security for one device;
- changing shared backend semantics solely to make one handset pass.

If one device fails, identify the generic Android/lifecycle/network cause and fix that cause. Then retest all representative devices.

## 6. Small-batch rule for future features

After the recovered stable base is promoted, features return only in small independently testable increments.

Profile-sharing/deep-link changes, if any are needed, must be separated into focused batches rather than combined with unrelated compatibility work.

Audio calling must be reintroduced incrementally:

- 09A: call session backend state only;
- 09B: basic two-way Agora audio;
- 09C: foreground/background/killed incoming-call notification behavior;
- 09D: speaker/earpiece/proximity routing;
- 09E: Bluetooth connect/disconnect/fallback;
- 09F: weak-network/reconnect behavior;
- 09G: missed/cancelled/history/block/suspension edge cases.

Each sub-batch must pass the full core regression smoke relevant to shared layers before the next sub-batch begins.

## 7. Firebase deployment rule

NearMeU consumer app is the canonical owner of shared Firebase deployables. Admin work must not deploy shared Firebase resources during this recovery/release path.

Before any Firebase deployment:

1. Verify active Firebase project is `nearmeu-e82c7`.
2. Record exact function/rule diff.
3. Confirm backward compatibility with the current stable client.
4. Confirm App Check/Auth requirements.
5. Deploy only the intended resources; avoid broad `firebase deploy` when a narrower deployment is possible.
6. Record the resulting production state in stable-base metadata.

## 8. Production vs physical-test App Check

- Play-distributed production release uses Play Integrity.
- Local physical-test builds may use the Firebase App Check debug provider only through an explicit test build configuration.
- Production security enforcement must not be disabled to make sideload testing pass.
- Debug tokens are device/test credentials, must not be shared publicly, and should be revoked when exposed or no longer needed.

## 9. Stable-base promotion sequence

A future stable base is promoted only in this order:

`code complete -> CI PASS -> signed artifact -> physical regression PASS -> owner acceptance -> docs sync -> GitHub recovery point -> PC full backup -> backup verification -> stable-base promotion -> next batch`

Skipping the PC backup or backup verification blocks the next feature batch.

## 10. Current target

The immediate target is not Batch 09. The immediate target is a new owner-verified Android-stable recovery base derived from original Batch 08 and only the minimum proven generic fixes required for the current backend/Android environment.

Until that target is accepted, Batch 08.1 and Batch 09 remain historical/reference work and are not sources of bulk runtime changes.
