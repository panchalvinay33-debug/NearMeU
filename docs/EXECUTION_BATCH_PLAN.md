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
- Final documented/recovery commit: `f487be76f958c06966e15f3db9cbbec65f5cfa9c`
- Accepted merged Batch 03 runtime commit: `e98bd0ebe86dad1f689723a9e96f35095a015a7b`
- Accepted PR: `#90`
- Version: `1.0.6+7`
- APK: `NearMeU-Batch-03-v1.0.6-7-Signed.apk`
- APK SHA-256: `a5e1c9b9a89e83b39023b95a8b1c8c2fd8c33e8cd120ad63c55a68cfe8c7d024`
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

## Active batch

### Batch 04 — Clear Chat and deletion semantics

Branch: `batch/04-clear-chat-deletion-semantics`

Target version: `1.0.7+8`

Scope under implementation/verification:

- trusted per-user Clear Chat cutoff (`clearStates.<uid>.clearedAt`) so cleared content cannot reappear from ordinary cloud/local replay;
- local encrypted chat rows and referenced downloaded media purged through the clear cutoff;
- other participant remains unaffected;
- cleared conversation stays out of the actor's chat list until genuinely newer post-clear activity exists;
- Delete for Me removes only the current user's copy and does not recreate already-expired delivery-cloud messages;
- Delete for Everyone continues to use the trusted sender-only 60-minute unsend path, with local media/content detachment hardened;
- cross-device cloud deletion markers reconcile into local removal while available;
- one focused physical test after CI, signing and production `clearPrivateChat` deployment pass.

Batch 04 cannot replace the official recovery base until all acceptance gates are complete.

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
