# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-01

Every runtime change is completed as one focused batch. A later batch does not begin until the current batch has passed automated tests, signed APK build, physical-device checks, owner review and documentation update.

## Governing rule

1. Start from the current official recovery/main state.
2. Use the canonical local workspace `F:\NearMeU` on the owner Windows machine.
3. Create one short-lived branch.
4. Freeze scope before coding.
5. Implement only that batch.
6. Run Flutter, Firebase Rules and Cloud Functions checks as applicable.
7. Build a permanently signed APK for runtime changes.
8. Install with `adb install -r`; never uninstall/wipe unless an explicitly approved clean-install scenario requires it.
9. Preserve package `com.nearmeu.nearmeu`, permanent signing identity and monotonically increasing versionCode.
10. Test on physical Android device(s), using two accounts/devices where behavior crosses users.
11. Record final commit, artifact, SHA-256, workflow evidence, physical result and known limitations.
12. Obtain owner acceptance.
13. Merge through a passing pull request.
14. Update recovery documentation with the actual merged-main runtime SHA.
15. Move `stable/official-recoverable-base` only after documentation is complete.
16. Synchronize `F:\NearMeU` to the promoted `main` / recovery state after each accepted batch.

## Current accepted starting point

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `e98bd0ebe86dad1f689723a9e96f35095a015a7b`
- Tested runtime commit: `72e25450a2df38cf44183d994a13f6acd61369e5`
- Final evidence head: `075c7e6d4abb05f40e4ed8b116aa20eddecf2c09`
- Accepted PR: `#90`
- Version: `1.0.6+7`
- APK: `NearMeU-Batch-03-v1.0.6-7-Signed.apk`
- APK SHA-256: `a5e1c9b9a89e83b39023b95a8b1c8c2fd8c33e8cd120ad63c55a68cfe8c7d024`
- Build workflow: `30693343758` / #25 — passed
- Quality workflow: `30693343752` / #418 — passed
- Production retention deployment: passed

## Completed batches

### Batch 00 — Governance, roadmap and decision freeze
Accepted.

### Batch 01 — Chat reliability and message-state truth
Accepted. Sent/server-accepted, delivered/synchronized and read/open tick truth physically verified.

### Batch 02 — Photo, video and voice-message reliability
Accepted. Includes media integrity checks, safe retry behavior, voice confirmation verification, partial-file cleanup and authentication/app-resume outbox recovery.

### Batch 03 — Local-first persistence and seven-day delivery cloud
Accepted. Successfully synchronized/downloaded chat history remains app-private local while temporary cloud delivery copies expire. Production retention stamping/purge functions were deployed and owner physical regression passed.

## Next batch

### Batch 04 — Clear Chat and deletion semantics

Scope goals:

- define and enforce Clear Chat behavior without accidental account/global data loss;
- distinguish local user-side clearing from any server-side deletion/unsend behavior;
- ensure local media associated with cleared messages is removed according to the approved rule;
- preserve the other participant's history unless an explicit cross-user deletion feature applies;
- keep seven-day cloud retention and local-first behavior consistent with Batch 03;
- verify restart/offline behavior and no resurrection of locally cleared history.

Physical tests must include two-device behavior, restart/offline cases, media cleanup, regression of ticks/media, and direct-update state preservation.

## Later batches

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

The recovery branch moves only when signed artifact/hash, signing identity, CI, required physical tests, owner acceptance, required production deployment, actual merged-main runtime SHA and recovery documentation are all recorded.
