# NearMeU Documentation Index

This is the canonical map for understanding, operating, testing, recovering and releasing NearMeU.

## Start here

1. [`OFFICIAL_RECOVERABLE_BASE.md`](OFFICIAL_RECOVERABLE_BASE.md) — exact accepted runtime/recovery state.
2. [`../config/project_state_manifest.json`](../config/project_state_manifest.json) — machine-readable current project state.
3. [`TEST_BATCH_REGISTER.md`](TEST_BATCH_REGISTER.md) — accepted batch evidence and next-batch status.
4. [`PRODUCT_DECISIONS.md`](PRODUCT_DECISIONS.md) — owner-approved product behavior.
5. [`EXECUTION_BATCH_PLAN.md`](EXECUTION_BATCH_PLAN.md) — controlled development order and gates.
6. [`MASTER_PROJECT_AUDIT.md`](MASTER_PROJECT_AUDIT.md) — broader historical/project audit; where older identifiers conflict with the current-state files above, the current accepted Batch 03 records take precedence.

## Canonical local workspace

- Primary owner Windows project folder: `F:\NearMeU`.
- Development, Git, Firebase deployment and recovery synchronization use `F:\NearMeU` unless the owner explicitly changes this path.
- Downloads clones are temporary only.
- After every accepted/promoted batch, `F:\NearMeU` must be synchronized to the promoted `main` / `stable/official-recoverable-base` state.
- `F:\NearMeU-OLD` and dated backup folders are backups, not the active project.

## Current accepted identifiers

- Development source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `e98bd0ebe86dad1f689723a9e96f35095a015a7b`
- Tested runtime commit: `72e25450a2df38cf44183d994a13f6acd61369e5`
- Final evidence head: `075c7e6d4abb05f40e4ed8b116aa20eddecf2c09`
- Accepted PR: `#90`
- Version: `1.0.6+7`
- Android package: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Accepted APK SHA-256: `a5e1c9b9a89e83b39023b95a8b1c8c2fd8c33e8cd120ad63c55a68cfe8c7d024`
- Build workflow: `30693343758` / #25 — passed
- Quality workflow: `30693343752` / #418 — passed
- Production retention functions: deployed successfully
- Next batch: `04` Clear Chat and deletion semantics

## Testing and recovery

- [`BATCH_03_PHYSICAL_TEST.md`](BATCH_03_PHYSICAL_TEST.md) — Batch 03 focused physical/backend test matrix.
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
