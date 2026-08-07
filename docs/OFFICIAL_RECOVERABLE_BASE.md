# NearMeU Official Recoverable Base

Last updated: 2026-08-08

Authoritative stability/recovery rules: `docs/ANDROID_STABILITY_AND_RECOVERY_RULEBOOK.md`.

## Current recovery position

The project is in controlled recovery/revalidation. Do not treat later Batch 08.1 or Batch 09 runtime work as the active base.

Recovery validation anchor:

- Repository: `panchalvinay33-debug/NearMeU`
- Recovery branch: `recovery/original-batch08-android-stable`
- Original Batch 08 merged runtime: `f83a6e92457f728f177dc062dcc9171c141a9217`
- Original Batch 08 tested runtime: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Pull request: `#100`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version at original Batch 08: `1.0.11+12`
- Calling code in this anchor: none
- Batch 08.1 changes in this anchor: none

This is an exact source recovery anchor. It is not automatically promoted as the new stable base until current backend compatibility and the full Android regression matrix pass again.

## Historical trusted baseline

Batch 07 remains the strongest historical functional baseline recorded before later compatibility/calling work:

- Tested runtime: `5ae058122d927c7e35257fb80ca5fa879f14b784`
- Merged runtime: `db48338e6528b61e1e486d6d158c9d62e641c977`
- Version: `1.0.10+11`
- Owner accepted: 2026-08-02

Its receiver-media pre-download/post-download Premium recovery physical evidence remains deferred and is not claimed as PASS.

## Recovery doctrine

1. Preserve current Batch 09 work as reference only.
2. Do not bulk-reapply Batch 08.1.
3. Audit current Firebase/Auth/App Check/Functions/Rules compatibility against original Batch 08 before changing client behavior.
4. Make only minimum proven generic Android fixes.
5. Do not add Samsung-, Motorola- or model-specific production code to obtain a PASS.
6. Run automated checks and the complete physical regression matrix.
7. Require explicit owner acceptance of the exact tested state.
8. Create a GitHub recovery point.
9. Create and verify a complete PC stable-base backup.
10. Only then promote the recovered base and restart feature development.

## Mandatory PC recovery copy

Every promoted stable base must also exist independently on the owner PC under:

`F:\NearMeU_Stable_Backups\Base-<batch>-<yyyyMMdd>-<shortSHA>`

Required contents include:

- complete source tree including `.git`;
- accepted signed APK/AAB;
- source/archive and artifact SHA-256 records;
- exact branch/commit/version/package/Firebase metadata;
- Firebase deployment-state notes without secret values;
- physical-test evidence;
- exact restore commands;
- compressed source archive.

The archive must be test-extracted and its expected Git commit verified before the next feature batch starts. A stable base without this PC backup is not considered fully closed.

Private keystores and secret values must not be placed in ordinary backup archives. Record only signing certificate fingerprints and secret names/configuration state.

## Current recovery checkout

To inspect the isolated recovery branch in the canonical workspace after preserving any local uncommitted work:

```powershell
cd "F:\NearMeU"
git fetch origin
git switch recovery/original-batch08-android-stable
git pull --ff-only
git rev-parse HEAD
```

The branch began from exact original Batch 08 merge:

`f83a6e92457f728f177dc062dcc9171c141a9217`

Do not reset `main`, delete Batch 09, or deploy Firebase resources merely to inspect this branch.

## Promotion gate

The new recovered stable base is promoted only after:

`backend audit PASS -> automated checks PASS -> signed artifact -> full Android physical regression PASS -> owner acceptance -> documentation sync -> GitHub recovery point -> PC full backup -> backup restore verification -> promotion`

Until then, this branch is a recovery candidate.

## Next feature work

No calling work resumes until the recovered base passes the promotion gate. Audio calling must then return in small independently testable sub-batches rather than one large integration.
