# NearMeU Documentation Index

This is the canonical map for understanding, operating, testing, recovering and releasing NearMeU.

## Start here

1. [`MASTER_PROJECT_AUDIT.md`](MASTER_PROJECT_AUDIT.md) — current accepted base, PC paths, APK hash, backup blueprint, roadmap, change control and audit result.
2. [`OFFICIAL_RECOVERABLE_BASE.md`](OFFICIAL_RECOVERABLE_BASE.md) — exact recovery procedure, App Check dependency and physical acceptance rules.
3. [`../config/project_state_manifest.json`](../config/project_state_manifest.json) — machine-readable current state for tools and automation.

## Current accepted identifiers

- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted commit: `f9bc38572c715a017c8b261a5d805aa125ffe7a5`
- Android package: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Accepted APK SHA-256: `587CD1B328A1CAEB659A0C5D0604609C5E6A381B61EFC6D0ACD9D3C2B1BDE00C`

## Product and roadmap

- [`final/NEARMEU_FINAL_BASELINE.md`](final/NEARMEU_FINAL_BASELINE.md) — historical detailed non-calling V1 scope; the master audit takes precedence for current identifiers.
- [`final/ROADMAP_AND_RELEASE_PLAN.md`](final/ROADMAP_AND_RELEASE_PLAN.md) — detailed release planning; use the master audit for current phase order.
- Issue `#41 Complete NearMeU production launch setup` — active production checklist.

## Backup and recovery

- [`MASTER_PROJECT_AUDIT.md`](MASTER_PROJECT_AUDIT.md) — owner PC details and complete backup set.
- [`OFFICIAL_RECOVERABLE_BASE.md`](OFFICIAL_RECOVERABLE_BASE.md) — source/APK/App Check recovery.
- [`final/BACKUP_AND_RECOVERY_PLAN.md`](final/BACKUP_AND_RECOVERY_PLAN.md) — Firebase retention and restore planning.
- [`../.github/workflows/recovery-base-apk.yml`](../.github/workflows/recovery-base-apk.yml) — signed recovery APK, checksum, certificate report and manifest generation.

## Development and architecture

- [`../README.md`](../README.md) — concise repository entry point.
- [`LOCAL_FIRST_MEDIA_RELEASE_RUNBOOK.md`](LOCAL_FIRST_MEDIA_RELEASE_RUNBOOK.md) — local-first message/media behavior.
- [`V1_HARDENING_PLAN.md`](V1_HARDENING_PLAN.md) — historical plan only; not the current source of truth.

## Security and Firebase

- [`PRODUCTION_READINESS_AUDIT.md`](PRODUCTION_READINESS_AUDIT.md) — source-level readiness findings.
- [`APP_CHECK_ROLLOUT.md`](APP_CHECK_ROLLOUT.md) — debug and Play Integrity rollout.
- [`OBSERVABILITY_ROLLOUT.md`](OBSERVABILITY_ROLLOUT.md) — privacy-safe observability rollout.
- [`../firestore.rules`](../firestore.rules) — Firestore client-access policy.
- [`../storage.rules`](../storage.rules) — Storage client-access policy.
- [`../firestore.indexes.json`](../firestore.indexes.json) — required indexes.
- [`../functions/bootstrap.js`](../functions/bootstrap.js) — secure Functions entry point.

## Testing

- [`ANDROID_PHONE_SMOKE_TEST.md`](ANDROID_PHONE_SMOKE_TEST.md) — practical phone smoke test.
- [`PHYSICAL_ANDROID_TESTING.md`](PHYSICAL_ANDROID_TESTING.md) — APK, App Check and two-device testing.
- [`REALTIME_STABILITY_TEST_PLAN.md`](REALTIME_STABILITY_TEST_PLAN.md) — presence, notifications, Nearby and unread validation.
- [`RELEASE_ACCEPTANCE_CHECKLIST.md`](RELEASE_ACCEPTANCE_CHECKLIST.md) — pre-distribution acceptance.
- [`../.github/workflows/quality.yml`](../.github/workflows/quality.yml) — automated quality gate.

## Production release

- [`PRODUCTION_RELEASE_RUNBOOK.md`](PRODUCTION_RELEASE_RUNBOOK.md) — signing, Firebase deployment, AAB and internal testing.
- [`PLAYSTORE_READY.md`](PLAYSTORE_READY.md) — Play readiness notes.

## Document precedence

When documents disagree, use this order:

1. `docs/MASTER_PROJECT_AUDIT.md`
2. `config/project_state_manifest.json`
3. `docs/OFFICIAL_RECOVERABLE_BASE.md`
4. Current `main` source, rules and workflows
5. `README.md` and this index
6. Topic-specific runbooks
7. Historical plans, old PR descriptions and closed issues

GitHub intentionally does not store keystores, passwords, App Check tokens, test-account credentials, live Firebase data or Play Console secrets.
