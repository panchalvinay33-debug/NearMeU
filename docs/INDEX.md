# NearMeU Documentation Index

Last updated: 2026-08-08

This is the canonical map for understanding, operating, testing, recovering and releasing NearMeU during the current stability recovery.

## Start here — current precedence

1. [`ANDROID_STABILITY_AND_RECOVERY_RULEBOOK.md`](ANDROID_STABILITY_AND_RECOVERY_RULEBOOK.md) — authoritative recovery, Android compatibility, stable-base and PC-backup rules.
2. [`OFFICIAL_RECOVERABLE_BASE.md`](OFFICIAL_RECOVERABLE_BASE.md) — current original-Batch08 recovery anchor and promotion gate.
3. [`TEST_BATCH_REGISTER.md`](TEST_BATCH_REGISTER.md) — historical batch status plus current recovery-validation status.
4. [`EXECUTION_BATCH_PLAN.md`](EXECUTION_BATCH_PLAN.md) — controlled development order and gates.
5. [`PRODUCT_DECISIONS.md`](PRODUCT_DECISIONS.md) — owner-approved product behavior where it does not conflict with the recovery rulebook.
6. Historical audit/planning files — context only.

## Current recovery identifiers

- Recovery validation branch: `recovery/original-batch08-android-stable`
- Original pre-calling Batch 08 merge anchor: `f83a6e92457f728f177dc062dcc9171c141a9217`
- Original Batch 08 tested runtime: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Original Batch 08 PR: `#100`
- Android package: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Batch 08.1: historical/reference only; not an active development base
- Batch 09: frozen / not accepted / do not merge during recovery

The recovery branch contains documentation commits after the original Batch 08 anchor. The runtime anchor remains the exact commit above; documentation changes do not mean Batch 08 has already been reaccepted against the current backend.

## Android product doctrine

NearMeU targets generic Android behavior. Samsung and Motorola are representative physical test devices, not special product targets. Fix generic Android lifecycle, permission, network and capability causes; do not introduce OEM-specific hacks simply to produce a device PASS.

## Canonical local workspace and stable backups

- Active owner workspace: `F:\NearMeU`.
- Mandatory stable backup root: `F:\NearMeU_Stable_Backups`.
- Temporary clones/downloads/artifacts are not stable backups.
- Every owner-accepted stable base requires an independent PC full-source recovery package in addition to GitHub/CI artifacts.
- Previous stable backups must remain preserved when a newer stable base is promoted.

A stable backup must include complete source with `.git`, accepted signed artifact(s), SHA-256 records, base/Firebase-state metadata, physical-test evidence and exact restore commands. It must be test-extracted/verified before the next feature batch starts.

## Current recovery flow

`freeze -> original Batch08 anchor -> backend compatibility audit -> automated checks -> signed test artifact -> full Android physical regression -> owner acceptance -> docs sync -> GitHub recovery point -> PC full backup -> backup verification -> stable-base promotion -> next feature`

Calling does not resume before this flow completes.

## Testing and release references

- [`RELEASE_ACCEPTANCE_CHECKLIST.md`](RELEASE_ACCEPTANCE_CHECKLIST.md) — pre-distribution acceptance checks.
- [`ANDROID_PHONE_SMOKE_TEST.md`](ANDROID_PHONE_SMOKE_TEST.md) — practical phone smoke testing where still applicable.
- [`PHYSICAL_ANDROID_TESTING.md`](PHYSICAL_ANDROID_TESTING.md) — physical Android testing guidance where still applicable.
- [`PRODUCTION_RELEASE_RUNBOOK.md`](PRODUCTION_RELEASE_RUNBOOK.md) — production signing/deployment guidance where still applicable.
- [`../.github/workflows/quality.yml`](../.github/workflows/quality.yml) — automated quality gate.

When any older document conflicts with the four current recovery documents at the top of this index, the current recovery documents take precedence.

GitHub must not store private keystores, passwords, raw App Check debug tokens, test-account credentials, live Firebase data or secret values.
