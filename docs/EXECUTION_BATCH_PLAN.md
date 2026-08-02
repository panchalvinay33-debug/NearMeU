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

Batch 08 — Profile sharing and deep-link recovery — is owner accepted.

- Tested runtime: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Runtime merge: `f83a6e92457f728f177dc062dcc9171c141a9217`
- PR: `#100`
- Version: `1.0.11+12`
- Build #90 / run `30750777554`: PASS
- Quality #493 / run `30750777555`: PASS
- Physically tested signed debug APK SHA-256: `4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412`
- Signed release APK SHA-256: `ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde`
- Owner acceptance: 2026-08-02
- Known evidence notes: Batch 07 receiver-media pre/post-download physical proof remains owner-deferred; Batch 08 custom-scheme fallback was not separately screenshot-verified although HTTPS warm/cold app links were physically verified.

Batches 00 through 08 are accepted.

## Next batch

### Batch 09 — Agora audio calling

Frozen direction:

- audio calling only; video remains Batch 10;
- preserve existing chat, Premium, recovery, profile-sharing and deletion semantics;
- use trusted backend authorization for any call-initiation entitlement decisions;
- actual call audio is not recorded or backed up;
- call-state, permission, connection, hangup/failure behavior must be tested on real devices;
- no owner-admin Premium mutation work in Batch 09;
- no Play purchase-verification or Play Store readiness scope creep.

## Later batches

- Batch 10 — Agora video calling
- Batch 11 — Owner-only Premium administration / purchase-verification work
- Batch 12 — Full regression and Play Store readiness, including production App Check / Play Integrity readiness

## Recovery-base movement rule

`stable/official-recoverable-base` moves only after CI, signing, physical acceptance, required production actions and final documentation are complete. A known deferred evidence item must remain explicitly recorded rather than silently converted to PASS.
