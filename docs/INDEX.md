# NearMeU Documentation Index

This is the canonical map for understanding, operating, testing, releasing, and recovering NearMeU. Start with the final baseline and then follow only the section relevant to the task.

## 1. Product and project state

- [`final/NEARMEU_FINAL_BASELINE.md`](final/NEARMEU_FINAL_BASELINE.md) — approved non-calling V1 scope and completion status.
- [`final/ROADMAP_AND_RELEASE_PLAN.md`](final/ROADMAP_AND_RELEASE_PLAN.md) — remaining deployment, testing, and Play Store steps.
- [`final/BACKUP_AND_RECOVERY_PLAN.md`](final/BACKUP_AND_RECOVERY_PLAN.md) — backup retention, restore flow, and ownership requirements.
- [`../config/project_state_manifest.json`](../config/project_state_manifest.json) — machine-readable project status for tools and automation.

## 2. Development and architecture

- [`../README.md`](../README.md) — repository entry point, stack, architecture, commands, and scope boundaries.
- [`V1_HARDENING_PLAN.md`](V1_HARDENING_PLAN.md) — historical hardening plan; use the final roadmap for current status.
- [`LOCAL_FIRST_MEDIA_RELEASE_RUNBOOK.md`](LOCAL_FIRST_MEDIA_RELEASE_RUNBOOK.md) — local-first message/media behavior and release checks.

## 3. Security and Firebase

- [`PRODUCTION_READINESS_AUDIT.md`](PRODUCTION_READINESS_AUDIT.md) — current source-level audit findings, confirmed safeguards, external blockers, and merge gates.
- [`APP_CHECK_ROLLOUT.md`](APP_CHECK_ROLLOUT.md) — App Check debug and Play Integrity rollout.
- [`OBSERVABILITY_ROLLOUT.md`](OBSERVABILITY_ROLLOUT.md) — privacy-safe Crashlytics, Analytics, and Performance rollout.
- [`../firestore.rules`](../firestore.rules) — authoritative Firestore client-access policy.
- [`../storage.rules`](../storage.rules) — authoritative Storage client-access policy.
- [`../firestore.indexes.json`](../firestore.indexes.json) — required production indexes.
- [`../functions/bootstrap.js`](../functions/bootstrap.js) — secure Cloud Functions deployment entry point.

## 4. Testing

- [`ANDROID_PHONE_SMOKE_TEST.md`](ANDROID_PHONE_SMOKE_TEST.md) — practical physical-phone smoke test.
- [`PHYSICAL_ANDROID_TESTING.md`](PHYSICAL_ANDROID_TESTING.md) — debug APK, App Check token, and two-device testing.
- [`REALTIME_STABILITY_TEST_PLAN.md`](REALTIME_STABILITY_TEST_PLAN.md) — presence, notifications, Nearby, and unread validation.
- [`RELEASE_ACCEPTANCE_CHECKLIST.md`](RELEASE_ACCEPTANCE_CHECKLIST.md) — single authoritative pre-distribution and production acceptance checklist.
- [`../.github/workflows/quality.yml`](../.github/workflows/quality.yml) — authoritative automated quality gate.

## 5. Production release

- [`PRODUCTION_RELEASE_RUNBOOK.md`](PRODUCTION_RELEASE_RUNBOOK.md) — signing, Firebase deployment, AAB generation, and internal testing.
- [`PLAYSTORE_READY.md`](PLAYSTORE_READY.md) — readiness notes and external Play Console work.
- [`CHANGELOG.md`](CHANGELOG.md) — historical release changes, when present.

## 6. Legal and store material

Legal/store drafts may contain owner-controlled placeholders. Never publish them until the owner has supplied and reviewed the real support email, legal identity, jurisdiction, URLs, retention wording, and Play Console declarations.

## 7. Database project-state record

The project manifest may be written to Firestore from a trusted admin environment:

```powershell
cd functions
npm run project-state:check
$env:NEARMEU_EXPECTED_FIREBASE_PROJECT_ID="nearmeu-e82c7"
npm run project-state:store
```

Canonical records:

- `systemProjectState/current`
- `systemProjectStateHistory/non-calling-final-baseline`

## Document precedence

When documents appear to disagree, use this order:

1. `config/project_state_manifest.json`
2. `docs/final/NEARMEU_FINAL_BASELINE.md`
3. `docs/final/ROADMAP_AND_RELEASE_PLAN.md`
4. Current source code, Firebase rules, and CI workflows
5. Older historical plans and PR descriptions

Old PR descriptions explain history but are not the current operating contract.
