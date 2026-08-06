# NearMeU Project Operating Blueprint

Status: Base 08 recovery hardening
Last updated: 2026-08-06

This is the first operational document to read when opening NearMeU. It explains the current accepted product boundary, where the project lives, how work is allowed to proceed, how production is deployed, how evidence is recorded, and how to return to the official base without reconstructing history manually.

## 1. Project identity

- Repository: `panchalvinay33-debug/NearMeU`
- Canonical PC workspace: `F:\NearMeU`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Primary source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`
- Current accepted product boundary: Batches 00 through 08 only.
- Work after Batch 08 is not part of the accepted runtime unless a future owner-approved batch completes the full acceptance process.

## 2. Accepted scope through Base 08

Accepted work includes:

- governance and controlled change process;
- chat reliability and message-state truth;
- photo/video/voice-message reliability;
- local-first encrypted persistence and seven-day temporary delivery cloud;
- Clear Chat and delete/unsend semantics;
- identity continuity, close/reactivation handling;
- Premium entitlement foundation;
- six-month Premium recovery architecture;
- profile sharing, opaque revocable public links and HTTPS deep-link recovery;
- Base08 re-certification stabilization for Firestore chat indexes, delivered receipts, online presence and accurate About-screen version display.

Persistent evidence note: Batch 07 receiver-media pre-download/post-download Premium recovery remains OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS until separately physically tested. Batch 08 custom `nearmeu://` fallback remains implemented but not separately screenshot-verified; HTTPS warm/cold links were physically verified.

## 3. Source-of-truth hierarchy

When documents disagree, use this order:

1. `docs/PROJECT_OPERATING_BLUEPRINT.md`
2. `config/official_base_manifest.json`
3. `docs/MASTER_PROJECT_AUDIT.md`
4. `docs/OFFICIAL_RECOVERABLE_BASE.md`
5. `config/project_state_manifest.json`
6. `docs/TEST_BATCH_REGISTER.md`
7. `docs/EXECUTION_BATCH_PLAN.md`
8. current accepted `main` source and workflows

Historical branches, PRs and screenshots cannot override the official-base manifest.

## 4. Hard change-control rule

Every runtime batch follows exactly:

`Freeze scope → branch from accepted base → code → CI → permanently signed APK → focused physical test → owner PASS → merge → deploy exact main SHA if production changes are required → production-state audit → documentation → recovery promotion → local sync → temporary branch cleanup → next batch unlock`

A batch is NOT accepted merely because code was merged or CI passed.

A batch becomes accepted only when all required gates are complete and its exact accepted state is written into `config/official_base_manifest.json`.

## 5. Branch rules

Long-lived branches:

- `main`
- `stable/official-recoverable-base`

All runtime, stabilization and documentation branches are temporary.

Rules:

- A new batch starts from the current accepted `main`/recovery state.
- Only one active runtime batch at a time.
- No future batch begins while the previous batch has pending physical acceptance, production cleanup, docs, recovery promotion or local sync.
- Temporary branches are deleted after accepted closeout when permissions/tools allow it. If deletion is unavailable, they must point to the accepted base and contain no unique active runtime code.
- Closed/superseded PRs are historical evidence only.

## 6. CI and signing gates

Before owner physical acceptance, the exact candidate must pass applicable checks:

- Dart formatter;
- Flutter analyze / compile checks;
- Flutter unit/widget tests;
- Firebase Rules emulator tests;
- Cloud Functions tests and secure module loading;
- permanently signed debug APK build;
- signing-certificate verification;
- signed release build when required.

Never physically certify an APK whose exact source/merge ref and SHA are unknown.

## 7. Physical acceptance rule

The owner tests the exact permanently signed candidate.

The acceptance record must include:

- source branch/head SHA;
- workflow run IDs;
- artifact IDs and digests;
- APK SHA-256;
- signing certificate;
- physical test result;
- known deferred items;
- owner decision and date.

Deferred evidence must remain explicitly deferred and must never be converted to PASS by assumption.

## 8. Production deployment rule

Production Firebase deployment is allowed only from a clean local checkout of the exact reviewed `origin/main` SHA.

Never deploy production Firebase resources from an unmerged feature branch.

Before deployment run:

```powershell
cd F:\NearMeU
.\tool\verify_deployment_gate.ps1
```

Deploy repository-managed Firebase resources only from source control. Do not create permanent console-only rules/index/function configuration.

Recommended order when all resources need deployment:

1. Firestore indexes/rules;
2. Storage rules;
3. Cloud Functions;
4. Hosting if changed by the batch;
5. production-state audit.

Use targeted deployment for a narrowly scoped hotfix when possible.

## 9. Production-state audit rule

After every production deployment run:

```powershell
.\tool\audit_production_state.ps1
```

This compares deployed Cloud Functions against the exports of `functions/bootstrap.js`. Unexpected deployed Functions are production drift and block batch acceptance.

Examples of prohibited drift:

- an Admin function left deployed after its source was removed;
- an abandoned calling function still running;
- a function deployed from a feature branch but absent from accepted `main`;
- stale index exemptions that change normal query behavior.

No batch closes while unexplained production drift exists.

## 10. One-command source recovery

Normal source recovery:

```powershell
cd F:\NearMeU
.\tool\restore_official_base.ps1
```

The script fetches origin, reads the accepted SHA from `config/official_base_manifest.json`, switches to `main`, resets the working source to the official accepted SHA and verifies project identity.

By default it refuses to destroy uncommitted local work. Use `-Force` only when the owner intentionally wants to discard local changes.

This removes the need to remember old branches or reconstruct a base manually.

## 11. Production recovery

Source recovery and production recovery are separate safety operations.

After source recovery, first audit production:

```powershell
.\tool\audit_production_state.ps1
```

If deployed resources do not match accepted source, remove only confirmed extras and redeploy accepted Firebase resources from the recovered source. Never delete user data as part of source recovery.

## 12. Recovery promotion rule

`stable/official-recoverable-base` moves only after:

- candidate CI PASS;
- permanent signing PASS;
- physical acceptance PASS;
- required production actions PASS;
- production-state audit PASS;
- docs updated;
- `config/official_base_manifest.json` updated;
- owner acceptance recorded.

After promotion, `main`, recovery branch and canonical local workspace must all resolve to the same accepted state before any new runtime batch begins.

## 13. Backup rule

A complete accepted-base backup contains:

- exact Git SHA;
- recovery branch;
- official base manifest;
- signed debug APK and SHA-256;
- signed release artifact when applicable;
- workflow run IDs and artifact IDs/digests;
- permanent signing certificate fingerprint;
- Firebase project ID;
- production resource audit result;
- physical acceptance result;
- owner acceptance date;
- encrypted owner-controlled keystore backup in at least two locations;
- Firebase/Google ownership recovery access.

Never commit keystores, passwords, App Check debug tokens, private credentials or live user data.

## 14. Version rule

`pubspec.yaml` is the single application version source.

- versionName is the value before `+`;
- versionCode is the integer after `+`;
- Play uploads must always use a versionCode greater than any previously uploaded versionCode;
- About screen must read runtime package info and must not hardcode a fake version.

## 15. Current roadmap policy

The currently accepted project ends at Base 08.

Future work is intentionally locked. Historical Batch09/Admin experiments are not accepted product scope.

A future batch can start only after the owner explicitly unlocks it. Its scope must then be selected again from the roadmap and started from the current official base.

## 16. Opening-the-project checklist

When NearMeU is opened after days or months, read:

1. `README.md` — quick orientation;
2. `docs/PROJECT_OPERATING_BLUEPRINT.md` — how the project works;
3. `config/official_base_manifest.json` — exact accepted machine truth;
4. `docs/MASTER_PROJECT_AUDIT.md` — detailed history and evidence.

Then run:

```powershell
cd F:\NearMeU
git status
git rev-parse HEAD
```

If there is any doubt about the working copy, run `tool\restore_official_base.ps1` before starting work.
