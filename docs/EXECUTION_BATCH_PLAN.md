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
- Final promoted main/recovery SHA: `3b749c8d7a320b71446245f99c694fdf85d9ccc4`
- Accepted runtime merge: `44143f612cbf8b7adf6d591abe74aac2c6397704`
- Accepted PR: `#94`
- Version: `1.0.8+9`
- Package: `com.nearmeu.nearmeu`
- Tested runtime: `d2868b97dc931a49f625f4711db4b555fecd34ec`
- Tested signed debug APK SHA-256: `c3371eb86c73a090b311c4d42656d8eaf799025aa04cd56da3bc6f51faeaf406`
- Physical owner acceptance: PASS on 2026-08-01

## Completed batches

- Batch 00 — Governance, roadmap and decision freeze — accepted.
- Batch 01 — Chat reliability and message-state truth — accepted.
- Batch 02 — Photo/video/voice-message reliability — accepted.
- Batch 03 — Local-first persistence and seven-day delivery cloud — accepted.
- Batch 04 — Clear Chat and deletion semantics — accepted/promoted.
- Batch 05 — Identity, account close and reactivation — accepted/promoted.

## Active batch

### Batch 06 — Premium entitlement foundation

Branch: `batch/06-premium-entitlement-foundation`

Target version: `1.0.9+10`

Implemented/verification scope:

- single private Premium plan with no public badge;
- server-only `premiumEntitlements/{uid}` truth, evaluated from independent `googlePlay` and `admin` grants;
- missing, disabled or expired grants resolve to Free;
- either valid Google Play or admin grant can independently keep Premium active, so future admin revocation cannot silently cancel a valid Play purchase;
- trusted callable `getMyPremiumEntitlement(asia-south1)` exposes only the current user's effective entitlement;
- client Premium state is read through the callable, never from a client-writable local/Firestore flag;
- Free text messaging remains unchanged;
- chat composer keeps mic and photo/video controls visible but locked for Free users;
- tapping a locked control refreshes trusted entitlement and only continues the original action if Premium is active;
- server `sendPrivateMediaMessage` independently enforces Premium for image, video and voice sends;
- received/local media remains viewable regardless of current Premium status;
- future Batch 09/10 outbound calling can reuse the same entitlement service;
- Batch 07 recovery and Batch 11 owner-admin mutation remain separate.

Explicitly not implemented in Batch 06:

- Google Play Billing purchase/receipt verification;
- six-month backup/restore;
- owner-facing Premium grant/revoke controls;
- public Premium badges;
- multiple Premium tiers/coins/trials.

Focused physical matrix: [`BATCH_06_PHYSICAL_TEST.md`](BATCH_06_PHYSICAL_TEST.md).

## Later batches

- Batch 07 — Six-month automatic Premium backup and restore
- Batch 08 — Profile sharing and deep-link recovery
- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — Owner-only Premium administration
- Batch 12 — Full regression and Play Store readiness

## Recovery-base movement rule

`main` is merged development truth. `stable/official-recoverable-base` is the last fully accepted runtime/documentation truth. It moves only after CI, permanent signing, physical owner acceptance, required production actions and final documentation are complete.
