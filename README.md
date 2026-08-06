# NearMeU

NearMeU is an Android-first Flutter application for privacy-aware nearby discovery and private one-to-one messaging.

## Read this first

The accepted project boundary is currently **Base 08 only**. Future Batch09/Admin/calling experiments are not part of the accepted runtime.

For the exact current truth, open these in order:

1. [`docs/PROJECT_OPERATING_BLUEPRINT.md`](docs/PROJECT_OPERATING_BLUEPRINT.md) — how NearMeU is developed, tested, deployed, backed up and recovered.
2. [`config/official_base_manifest.json`](config/official_base_manifest.json) — machine-readable accepted/candidate SHA, artifacts, gates and recovery target.
3. [`docs/MASTER_PROJECT_AUDIT.md`](docs/MASTER_PROJECT_AUDIT.md) — detailed project/evidence audit.
4. [`docs/CHANGE_LEDGER.md`](docs/CHANGE_LEDGER.md) — what changed, when, where it merged and why.
5. [`docs/OFFICIAL_RECOVERABLE_BASE.md`](docs/OFFICIAL_RECOVERABLE_BASE.md) — accepted recovery evidence.
6. [`docs/INDEX.md`](docs/INDEX.md) — full documentation map.

## One-command project summary

From the canonical PC workspace:

```powershell
cd F:\NearMeU
.\tool\show_project_state.ps1
```

This prints the accepted Base boundary, official recovery SHA, current local SHA/branch, version, fresh physical results, pending closeout gates, persistent evidence gaps and future-work lock.

## Project identity

| Item | Value |
|---|---|
| Repository | `panchalvinay33-debug/NearMeU` |
| Canonical PC folder | `F:\NearMeU` |
| Source of truth | `main` |
| Recovery branch | `stable/official-recoverable-base` |
| Accepted boundary | Batches `00–08` only |
| Android package | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| App version | `1.0.11+12` |
| Permanent signing cert SHA-256 | `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B` |

Do not copy accepted SHAs or artifact hashes from this README. Those values deliberately live in one machine-readable source: `config/official_base_manifest.json`.

## One-command recovery

```powershell
cd F:\NearMeU
.\tool\restore_official_base.ps1
```

This reads the official accepted SHA from the manifest and restores the source directly to that state. It refuses to destroy uncommitted work unless `-Force` is intentionally supplied.

Then audit Firebase production state:

```powershell
.\tool\audit_production_state.ps1
```

## Deployment gate

Before any production Firebase deployment:

```powershell
cd F:\NearMeU
.\tool\verify_deployment_gate.ps1
```

Production deploys are permitted only from a clean, reviewed `main` that exactly matches `origin/main`.

## Accepted Base08 capabilities

- authentication and adult onboarding;
- Nearby discovery and presence;
- private one-to-one text/reply/emoji messaging;
- photo, video and voice messages;
- encrypted local-first chat persistence;
- seven-day temporary delivery cloud;
- clear/delete/unsend semantics;
- identity continuity, close/reactivation;
- Premium entitlement and six-month recovery architecture;
- profile sharing with opaque revocable public IDs and HTTPS app links;
- Base08 stabilization for chat indexes, delivery receipts and online presence.

Known evidence remains explicit: Batch07 receiver-media pre/post-download Premium recovery is OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS; Batch08 custom `nearmeu://` fallback is implemented but was not separately screenshot-verified.

## Current freeze

No future runtime batch is active. Historical post-Base08 experiments are not accepted scope.

A future batch starts only after the owner explicitly unlocks it and only from the official recoverable base using the process in `docs/PROJECT_OPERATING_BLUEPRINT.md`.

## Repository structure

```text
android/                 Android configuration
config/                  Machine-readable project/recovery truth
functions/               Firebase Cloud Functions and tests
lib/                     Flutter application code
rules_tests/             Firebase emulator security tests
test/                    Flutter tests
docs/                    Blueprint, audit, ledger, acceptance and release docs
tool/                    State, recovery, deployment and production-audit scripts
.github/workflows/       CI and signed-build workflows
```

## Security boundary

GitHub must never contain the permanent keystore bytes, passwords, App Check debug tokens, private test credentials or live user data. Keystore/password backups remain encrypted and owner-controlled outside the repository.
