# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-01

Every runtime change is completed as one focused batch. A later batch does not begin until the current batch has passed automated tests, signed APK build, physical-device checks, owner review and documentation update.

## Governing rule

1. Start from the current official recovery/main state.
2. Create one short-lived branch.
3. Freeze scope before coding.
4. Implement only that batch.
5. Run Flutter, Firebase Rules and Cloud Functions checks as applicable.
6. Build a permanently signed APK for runtime changes.
7. Install with `adb install -r`; never uninstall/wipe unless an explicitly approved clean-install scenario requires it.
8. Preserve package `com.nearmeu.nearmeu`, permanent signing identity and monotonically increasing versionCode.
9. Test on physical Android device(s), using two accounts/devices where behavior crosses users.
10. Record final commit, artifact, SHA-256, workflow evidence, physical result and known limitations.
11. Obtain owner acceptance.
12. Merge through a passing pull request.
13. Update recovery documentation with the actual merged-main SHA.
14. Move `stable/official-recoverable-base` only after documentation is complete.

## Current accepted starting point

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `d7a8c800d48beb7f646fb4d76d0afd7fbfeafa56`
- Accepted feature commit: `bbed8998040099202e50e26c62782a04b6b9fe04`
- Accepted PR: `#88`
- Version: `1.0.5+6`
- APK: `NearMeU-Batch-02-v1.0.5-6-Signed.apk`
- APK SHA-256: `b355c854f210aea3787b937a46ab6714f60e18f7acf471779a4daf2655f43d76`
- Build workflow: `30687614764` / #20 — passed
- Quality workflow: `30687614766` / #411 — passed

## Completed batches

### Batch 00 — Governance, roadmap and decision freeze
Accepted.

### Batch 01 — Chat reliability and message-state truth
Accepted. Sent/server-accepted, delivered/synchronized and read/open tick truth physically verified.

### Batch 02 — Photo, video and voice-message reliability
Accepted. Includes media integrity checks, safe retry behavior, voice confirmation verification, partial-file cleanup and authentication/app-resume outbox recovery. Physical owner result: working.

## Next batch

### Batch 03 — Local-first persistence and seven-day delivery cloud

Product rule:

- Successfully downloaded text/media remains in app-private local storage until Clear Chat, applicable message deletion, app-data clear or uninstall.
- Seven days applies to the temporary cloud delivery copy, not to the valid local copy.
- Cloud cleanup must never remove a valid local copy.
- No expired placeholder is shown while a valid local file exists.

Required tests include cloud-expiry simulation, offline replay after expiry, app restart, receiver delivery timing, local-media survival, and a new-device/non-Premium recovery boundary.

## Later batches

- Batch 04 — Clear Chat and deletion semantics
- Batch 05 — Identity, account close and reactivation
- Batch 06 — Premium entitlement foundation
- Batch 07 — Six-month automatic Premium backup and restore
- Batch 08 — Profile sharing and deep-link recovery
- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — Owner-only Premium administration
- Batch 12 — Full regression and Play Store readiness

## Recovery-base movement rule

`main` is accepted development truth after merge. `stable/official-recoverable-base` is the last indisputably recoverable runtime/documentation truth.

The recovery branch moves only when the signed artifact/hash, signing identity, CI, required physical tests, owner acceptance, actual merged-main SHA and recovery documentation are all recorded.
