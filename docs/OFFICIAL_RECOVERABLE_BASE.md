# NearMeU V1 Recovery and Launch-Base Record

Last updated: 2026-08-08

## Purpose

This document explains how to preserve and recover the current V1 launch line while launch stabilization is in progress. It does not define a future feature roadmap.

## Current identifiers

- Repository: `panchalvinay33-debug/NearMeU`
- Active launch branch: `v1/testing-baseline`
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
- owner admin state was restored.

A valid recovery therefore requires both source and Firebase compatibility. Restoring only Git source while leaving an incompatible Firebase backend is not considered a complete recovery.

## Source recovery during launch stabilization

```powershell
git fetch origin
git checkout v1/testing-baseline
git reset --hard origin/v1/testing-baseline
git clean -fd
```

Before using any recovered source against Firebase, verify that its rules/indexes/functions/storage configuration is the accepted V1 set.

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

## Owner-controlled backup requirements

Keep outside the repository:

- Android signing keystore in protected backups;
- signing passwords/aliases in a password manager;
- Firebase ownership/recovery access;
- App Check debug tokens;
- service-account private keys;
- test-account credentials;
- live Firestore/Storage backups when intentionally taken;
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

New product work is not specified here. Anything beyond the accepted V1 launch is reconsidered as V2 after launch.