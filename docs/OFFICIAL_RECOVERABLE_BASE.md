# NearMeU V1 Recovery and Launch-Base Record

Last updated: 2026-08-08

## Purpose

This document explains how to preserve and recover the current V1 launch line while launch stabilization is in progress. It does not define a future feature roadmap.

## Current identifiers

- Repository: `panchalvinay33-debug/NearMeU`
- Active launch branch: `v1/testing-baseline`
- Active local source folder: `F:\NearMeU`
- Private recovery folder: `F:\NearMeU_Private_Backup`
- Temporary Firebase audit/tooling folder: `F:\NearMeU_Firebase_Audit` until final V1 verification is complete
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Final launch commit: not frozen yet
- Final launch APK/AAB checksum: not frozen yet

The old recoverable-base records remain historical evidence. They do not replace the current V1 launch checklist or the backend state verified on 2026-08-08.

## Current V1 backend recovery state

On 2026-08-08 the active Firebase project was intentionally aligned to the current V1 base:

- later-feature Firestore data was backed up and removed from the active backend;
- later-feature recovery media was backed up and removed;
- V1 Firestore rules were deployed;
- V1 Firestore indexes were deployed;
- V1 Storage rules were deployed;
- V1 Cloud Functions were deployed and later-feature Functions removed;
- Cloud Functions tests passed 43/43;
- duplicate chat audit returned zero duplicate pairs;
- owner admin state was restored;
- legacy `users` / `privateProfiles` consistency was repaired with a PC backup taken before mutation.

A valid recovery therefore requires both source and Firebase compatibility. Restoring only Git source while leaving an incompatible Firebase backend is not considered a complete recovery.

## Single local source rule

`F:\NearMeU` is the only active project working copy. Do not create a new permanent working folder for every checkpoint.

Git commit/branch history is the source-code recovery mechanism. Private Firebase exports, service-account material, migration backups, old ZIP evidence and final release artifacts/checksums stay outside Git in `F:\NearMeU_Private_Backup`.

Old copies such as `NearMeU_V1_Deploy`, `NearMeU_V1_ProfileFix`, `NearMeU_Recovery08`, `NearMeU-OLD` and `NearMeU_OLD_ADVANCED_BACKUP` are not authoritative once the current `F:\NearMeU` clone and private backup are verified.

## Source recovery during launch stabilization

From `F:\NearMeU`:

```powershell
git fetch origin
git checkout v1/testing-baseline
git reset --hard origin/v1/testing-baseline
git clean -fd
```

Before using any recovered source against Firebase, verify that its rules/indexes/functions/storage configuration is the accepted V1 set.

## What makes a new recoverable base

A milestone becomes a new recoverable base only after the relevant sequence completes:

1. focused code/config change is accepted;
2. required automated tests pass;
3. physical testing passes when user-visible/runtime behavior changed;
4. accepted commit SHA is known;
5. `F:\NearMeU` is updated to that commit and working tree is clean;
6. Firebase production is deployed only when required and verified afterward;
7. required PC backup/audit evidence exists outside Git;
8. result is recorded in the project documents.

CI success alone is not enough when the behavior requires physical validation.

## App Check test dependency

Debug builds use Firebase App Check debug registration. The installation-specific debug token is intentionally kept outside Git.

- never commit the token;
- reinstall/clear-data may produce a new token;
- register the current debug token in Firebase Console for testing;
- release configuration uses Play Integrity and must be verified as part of the release candidate.

## Minimum physical recovery check

After installing a test build, verify:

- Google sign-in/session routing;
- existing complete profile opens the app without unnecessary onboarding;
- Nearby loads;
- Chats loads;
- a new text message can be sent/received;
- app restart preserves the expected authenticated state;
- no App Check/permission/backend mismatch blocks normal use.

## V1 launch acceptance

The authoritative acceptance requirements are in [`V1_LAUNCH_CHECKLIST.md`](V1_LAUNCH_CHECKLIST.md). The final launch commit and artifact checksum are recorded only after all open launch gates pass.

The detailed PC workspace/testing/deployment discipline is in [`WORKSPACE_AND_DEPLOYMENT_RULES.md`](WORKSPACE_AND_DEPLOYMENT_RULES.md).

## Owner-controlled backup requirements

Keep outside the repository, preferably under `F:\NearMeU_Private_Backup` or another protected backup location:

- Android signing keystore in protected backups;
- signing passwords/aliases in a password manager;
- Firebase ownership/recovery access;
- App Check debug tokens;
- service-account private keys;
- test-account credentials;
- live Firestore/Storage backups when intentionally taken;
- migration backups before destructive data changes;
- final accepted APK/AAB and checksum after launch acceptance.

GitHub should contain the source, rules, indexes, Functions, workflows and non-secret recovery instructions.

## Incident rule before launch

If a stabilization change breaks the current app:

1. stop the failing change;
2. identify the last physically verified V1 state;
3. verify Git source and Firebase deployed state together;
4. reproduce the failure on the focused change only;
5. fix and retest the affected launch gate;
6. do not expand scope while recovering.

## After V1 launch

The accepted V1 launch commit becomes the production/recovery anchor. New product work begins as V2 from that base only after V1 is released and its initial production behavior is reviewed.