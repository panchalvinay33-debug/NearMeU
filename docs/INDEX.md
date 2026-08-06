# NearMeU Documentation Index

Last updated: 2026-08-06

This is the documentation map for the currently accepted **Base 08** project boundary.

## Start here

Read these in this order:

1. [`PROJECT_OPERATING_BLUEPRINT.md`](PROJECT_OPERATING_BLUEPRINT.md) — complete operating model: project identity, PC path, branches, acceptance, deployment, backup and recovery.
2. [`../config/official_base_manifest.json`](../config/official_base_manifest.json) — exact machine-readable recovery target, candidate evidence and gate status.
3. [`MASTER_PROJECT_AUDIT.md`](MASTER_PROJECT_AUDIT.md) — detailed accepted history and evidence.
4. [`OFFICIAL_RECOVERABLE_BASE.md`](OFFICIAL_RECOVERABLE_BASE.md) — accepted/recovery evidence record.
5. [`TEST_BATCH_REGISTER.md`](TEST_BATCH_REGISTER.md) — batch acceptance status and persistent evidence gaps.
6. [`EXECUTION_BATCH_PLAN.md`](EXECUTION_BATCH_PLAN.md) — controlled work order; future runtime work is currently locked after Base08.
7. [`PRODUCT_DECISIONS.md`](PRODUCT_DECISIONS.md) — product behavior decisions.

## Project identity

- Repository: `panchalvinay33-debug/NearMeU`
- Canonical workspace: `F:\NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Android package: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Current version: `1.0.11+12`
- Accepted product boundary: Batches 00–08 only

Exact accepted SHA/artifact values belong in `config/official_base_manifest.json`; do not duplicate them into new docs unless they are acceptance evidence.

## Recovery and deployment tooling

- [`../tool/restore_official_base.ps1`](../tool/restore_official_base.ps1) — one-command source recovery to the manifest's official SHA.
- [`../tool/verify_deployment_gate.ps1`](../tool/verify_deployment_gate.ps1) — blocks production deployment from the wrong branch, dirty tree or unsynced main.
- [`../tool/audit_production_state.ps1`](../tool/audit_production_state.ps1) — compares deployed Firebase Functions with accepted `functions/bootstrap.js` exports.
- [`PRODUCTION_RELEASE_RUNBOOK.md`](PRODUCTION_RELEASE_RUNBOOK.md) — controlled Firebase/Play production release process.

## Physical testing and evidence

- [`BATCH_08_PHYSICAL_TEST.md`](BATCH_08_PHYSICAL_TEST.md) — Base08 physical/profile-sharing evidence plus re-certification record as updated.
- [`ANDROID_PHONE_SMOKE_TEST.md`](ANDROID_PHONE_SMOKE_TEST.md) — practical Android smoke checks.
- [`PHYSICAL_ANDROID_TESTING.md`](PHYSICAL_ANDROID_TESTING.md) — APK/App Check/two-device testing guidance.
- [`RELEASE_ACCEPTANCE_CHECKLIST.md`](RELEASE_ACCEPTANCE_CHECKLIST.md) — pre-distribution acceptance checklist.

## CI and recovery builds

- [`../.github/workflows/quality.yml`](../.github/workflows/quality.yml) — automated Flutter/Functions/Rules quality gate.
- [`../.github/workflows/recovery-base-apk.yml`](../.github/workflows/recovery-base-apk.yml) — permanently signed recoverable debug APK workflow.

## Current-state precedence

When any document conflicts, use:

1. `docs/PROJECT_OPERATING_BLUEPRINT.md`
2. `config/official_base_manifest.json`
3. `docs/MASTER_PROJECT_AUDIT.md`
4. `docs/OFFICIAL_RECOVERABLE_BASE.md`
5. `config/project_state_manifest.json`
6. `docs/TEST_BATCH_REGISTER.md`
7. `docs/EXECUTION_BATCH_PLAN.md`
8. accepted `main` source/rules/workflows
9. historical plans, old PRs and old branches

## Important external state

GitHub intentionally does not store keystore bytes, passwords, App Check debug tokens, live Firebase data, private test credentials or Play Console secrets. Those stay in protected GitHub secrets, encrypted owner backups and the appropriate Google/Firebase consoles.
