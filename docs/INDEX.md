# NearMeU Documentation Index

This is the canonical map for understanding, operating, testing, recovering and releasing NearMeU.

## Start here

1. [`OFFICIAL_RECOVERABLE_BASE.md`](OFFICIAL_RECOVERABLE_BASE.md) — exact accepted runtime/recovery state.
2. [`../config/project_state_manifest.json`](../config/project_state_manifest.json) — machine-readable current project state.
3. [`TEST_BATCH_REGISTER.md`](TEST_BATCH_REGISTER.md) — accepted batch evidence and next-batch status.
4. [`PRODUCT_DECISIONS.md`](PRODUCT_DECISIONS.md) — owner-approved product behavior.
5. [`EXECUTION_BATCH_PLAN.md`](EXECUTION_BATCH_PLAN.md) — controlled development order and gates.
6. [`MASTER_PROJECT_AUDIT.md`](MASTER_PROJECT_AUDIT.md) — broader historical/project audit; where older identifiers conflict with the three current-state files above, the current accepted Batch 02 recovery records take precedence.

## Canonical local workspace

- Primary local project folder on the owner Windows machine: `F:\NearMeU`.
- All future NearMeU development, Firebase deployment, Git operations and recovery-base synchronization should use `F:\NearMeU` as the canonical working copy unless the owner explicitly changes this path.
- Temporary clones under `C:\Users\<user>\Downloads` are not the canonical project workspace and should not be used as the long-term base.
- After every accepted/promoted batch, the local `F:\NearMeU` working copy should be synchronized to the promoted `main` / `stable/official-recoverable-base` state so the accepted base is also saved locally on the F: drive.
- Existing folders such as `F:\NearMeU-OLD` or dated backup folders are backups only; they must not be mistaken for the active project.

## Current accepted identifiers

- Development source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `d7a8c800d48beb7f646fb4d76d0afd7fbfeafa56`
- Accepted feature commit: `bbed8998040099202e50e26c62782a04b6b9fe04`
- Accepted PR: `#88`
- Version: `1.0.5+6`
- Android package: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Accepted APK SHA-256: `b355c854f210aea3787b937a46ab6714f60e18f7acf471779a4daf2655f43d76`
- Next batch: `03` local-first persistence and seven-day delivery cloud

## Testing and recovery

- [`BATCH_02_PHYSICAL_TEST.md`](BATCH_02_PHYSICAL_TEST.md) — Batch 02 focused physical test matrix.
- [`ANDROID_PHONE_SMOKE_TEST.md`](ANDROID_PHONE_SMOKE_TEST.md) — practical phone smoke test.
- [`PHYSICAL_ANDROID_TESTING.md`](PHYSICAL_ANDROID_TESTING.md) — APK/App Check/two-device testing.
- [`RELEASE_ACCEPTANCE_CHECKLIST.md`](RELEASE_ACCEPTANCE_CHECKLIST.md) — pre-distribution acceptance.
- [`../.github/workflows/quality.yml`](../.github/workflows/quality.yml) — automated quality gate.
- [`../.github/workflows/recovery-base-apk.yml`](../.github/workflows/recovery-base-apk.yml) — permanently signed recovery APK workflow.

## Production release

- [`PRODUCTION_RELEASE_RUNBOOK.md`](PRODUCTION_RELEASE_RUNBOOK.md) — signing, Firebase deployment, AAB and internal testing.
- [`PLAYSTORE_READY.md`](PLAYSTORE_READY.md) — Play readiness notes.

## Current-state precedence

When current-state documents disagree, use this order:

1. `config/project_state_manifest.json`
2. `docs/OFFICIAL_RECOVERABLE_BASE.md`
3. `docs/TEST_BATCH_REGISTER.md`
4. `docs/PRODUCT_DECISIONS.md`
5. `docs/EXECUTION_BATCH_PLAN.md`
6. Current `main` source/rules/workflows
7. `docs/MASTER_PROJECT_AUDIT.md` for broader historical context
8. Historical plans and old PR/issue descriptions

GitHub intentionally does not store keystores, passwords, App Check tokens, test-account credentials, live Firebase data or Play Console secrets.
