# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-01

Every runtime change is completed as one focused batch. A later batch starts only after automated tests, signed build, focused physical acceptance, owner approval, merge and recovery documentation are complete.

## Governing rule

1. Start from current promoted `main` / recovery state.
2. Use canonical workspace `F:\NearMeU`.
3. Use one short-lived runtime branch.
4. Freeze scope before coding.
5. Implement only that batch.
6. Run Flutter, Firebase Rules and Cloud Functions checks as applicable.
7. Build with the permanent Android signing identity.
8. Install using update mode (`adb install -r`), never uninstall/wipe for normal upgrades.
9. Preserve package `com.nearmeu.nearmeu` and monotonically increasing versionCode.
10. Physically test only the focused new behavior plus necessary regression smoke checks.
11. Record commit/artifact/hash/workflow evidence and owner decision.
12. Merge through a passing PR.
13. Update recovery docs and promote `stable/official-recoverable-base`.
14. Sync `F:\NearMeU` back to promoted `main`.

## Current accepted starting point

- Accepted batch: `05`
- Accepted runtime merge: `44143f612cbf8b7adf6d591abe74aac2c6397704`
- Accepted PR: `#94`
- Version: `1.0.8+9`
- Package: `com.nearmeu.nearmeu`
- Tested runtime: `d2868b97dc931a49f625f4711db4b555fecd34ec`
- Tested signed debug APK SHA-256: `c3371eb86c73a090b311c4d42656d8eaf799025aa04cd56da3bc6f51faeaf406`
- Recoverable artifact ID/digest: `8818404060` / `sha256:70505abc00881695754c70684ae4140ab05224c1c424d242d6cdc9d11e20e94c`
- Tested-runtime CI: Build #33 PASS, Quality #430 PASS
- Acceptance-head CI: Build #36 PASS, Quality #433 PASS
- Physical owner acceptance: PASS on 2026-08-01

## Completed batches

- Batch 00 — Governance, roadmap and decision freeze — accepted.
- Batch 01 — Chat reliability and message-state truth — accepted.
- Batch 02 — Photo/video/voice-message reliability — accepted.
- Batch 03 — Local-first persistence and seven-day delivery cloud — accepted.
- Batch 04 — Clear Chat and deletion semantics — accepted/promoted.
- Batch 05 — Identity, account close and reactivation — accepted/promoted. Reversible account closure, unavailable closed identity, messaging refusal while closed, same-account reactivation/profile recreation and retained chat continuity were physically accepted.

## Active / next batch

### Batch 06 — Premium entitlement foundation

Planned scope:

- one trusted server-side Premium entitlement model;
- Free versus Premium authorization exposed through a central client/service layer;
- no public Premium badge;
- Premium status cannot be unlocked by a local-only client flag;
- active/expired entitlement handling is deterministic;
- Free users keep text, incoming media playback and incoming call receipt according to frozen decisions;
- outbound photo/video/voice-message and future outbound calling checks use the same entitlement foundation;
- Batch 07 recovery and Batch 11 owner-admin grants build on this same entitlement truth.

Batch 06 implementation must inspect the current purchase/subscription code and frozen product decisions before modifying runtime behavior. Do not implement Batch 07 backup/restore or Batch 11 admin controls inside Batch 06.

## Later batches

- Batch 07 — Six-month automatic Premium backup and restore
- Batch 08 — Profile sharing and deep-link recovery
- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — Owner-only Premium administration
- Batch 12 — Full regression and Play Store readiness

## Recovery-base movement rule

`main` is merged development truth. `stable/official-recoverable-base` is the last fully accepted runtime/documentation truth. It moves only after CI, permanent signing, physical owner acceptance, required production actions and final documentation are complete.
