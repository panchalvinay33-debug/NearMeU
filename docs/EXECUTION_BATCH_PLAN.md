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
- Accepted merged Batch 04 runtime commit: `d387b5cf8db7d9e792673ada4dd1c1d2958c7aee`
- Accepted PR: `#92`
- Version: `1.0.7+8`
- Physically tested APK: `NearMeU-Batch-04-v1.0.7-8-Signed.apk`
- Physically tested APK SHA-256: `24e770e3b09cfcb2608b8a8283405cef282f62a4832a3e67fd3a625a2bd2deb8`
- Production `clearPrivateChat(asia-south1)` deployment: passed
- Final documented/recovery commit: pending this acceptance-doc merge and recovery fast-forward.

## Completed batches

### Batch 00 — Governance, roadmap and decision freeze
Accepted.

### Batch 01 — Chat reliability and message-state truth
Accepted. Sent/server-accepted, delivered/synchronized and read/open tick truth physically verified.

### Batch 02 — Photo, video and voice-message reliability
Accepted. Includes media integrity checks, safe retry behavior, voice confirmation verification, partial-file cleanup and authentication/app-resume outbox recovery.

### Batch 03 — Local-first persistence and seven-day delivery cloud
Accepted. Successfully synchronized/downloaded chat history remains app-private local while temporary cloud delivery copies expire. Production retention stamping/purge functions were deployed and owner physical regression passed.

### Batch 04 — Clear Chat and deletion semantics
Accepted. Trusted per-user Clear Chat cutoff, local encrypted purge, actor-only clearing, chat-list reappearance only for post-clear activity, Delete for Me hardening and Delete for Everyone local-media detachment were physically accepted. Production `clearPrivateChat` was deployed successfully.

## Next batch

### Batch 05 — Identity, account close and reactivation

Status: planned-next. Start only after this Batch 04 acceptance-doc PR merges and `stable/official-recoverable-base` is fast-forwarded to the exact final docs merge.

Approved scope direction:

- separate logout/session-end semantics from account-close semantics;
- define trusted account closed/active lifecycle state;
- prevent duplicate/ghost identity creation on reactivation;
- preserve or remove local encrypted state according to the approved account-close policy;
- ensure existing chat identity references remain safe and deterministic;
- support controlled reactivation of the same identity where permitted;
- keep direct-update, package/signing and existing accepted chat/media behavior regression-safe;
- use a short focused physical acceptance pass rather than repeating Batch 01–04 full matrices.

## Later batches

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
