# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-02

Every runtime change is one focused batch. A later batch starts only after automated tests, permanently signed build, focused physical acceptance, owner approval, merge, documentation sync, recovery promotion and canonical local workspace sync.

## Governing rule

1. Start from promoted `main` / recovery state.
2. Use canonical workspace `F:\NearMeU`.
3. Use one short-lived runtime branch.
4. Freeze scope before coding.
5. Run Flutter, Firebase Rules and Cloud Functions checks as applicable.
6. Build with permanent Android signing.
7. Install using `adb install -r`; never uninstall/wipe for normal upgrades.
8. Preserve package `com.nearmeu.nearmeu` and increasing versionCode.
9. Physically test focused new behavior plus necessary smoke checks.
10. Owner accepts or rejects the exact tested state.
11. Merge through a passing PR.
12. Sync authoritative docs and evidence.
13. Promote `stable/official-recoverable-base`.
14. Sync `F:\NearMeU` before starting the next runtime batch.

## Current accepted runtime

Batch 07 — Six-month Premium backup and restore — is owner accepted.

- Tested runtime: `5ae058122d927c7e35257fb80ca5fa879f14b784`
- Runtime merge: `db48338e6528b61e1e486d6d158c9d62e641c977`
- PR: `#98`
- Version: `1.0.10+11`
- Build #79 / run `30746260270`: PASS
- Quality #480 / run `30746260318`: PASS
- Physically tested signed debug APK SHA-256: `2af784329a1594a761877110c671508b19f8cd1cc2542d9079cc46a7b80025d1`
- Owner acceptance: 2026-08-02
- Known evidence gap: receiver-media pre-download/post-download recovery physical verification was owner-deferred and is not claimed as PASS.

Batches 00 through 07 are accepted.

## Next batch

### Batch 08 — Profile sharing and deep-link recovery

Frozen direction:

- privacy-safe profile sharing for Free and Premium users;
- revocable public identifier rather than exposing Firebase UID;
- deep-link/open-app recovery behavior;
- block/privacy rules must continue to apply;
- no calling work in this batch;
- no owner-admin Premium mutation or Play purchase verification in this batch;
- preserve accepted chat, local-first, delivery-cloud, deletion and Premium-recovery semantics.

## Later batches

- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — Owner-only Premium administration / purchase-verification work
- Batch 12 — Full regression and Play Store readiness, including production App Check / Play Integrity readiness

## Recovery-base movement rule

`stable/official-recoverable-base` moves only after CI, signing, physical acceptance, required production actions and final documentation are complete. A known deferred evidence item must remain explicitly recorded rather than silently converted to PASS.
