# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-01

Every runtime change is completed as one focused batch. A later batch starts only after automated tests, signed build, focused physical acceptance, owner approval, merge and recovery documentation are complete.

## Governing rule

1. Start from current promoted `main` / recovery state.
2. Use canonical workspace `F:\NearMeU`.
3. Use one short-lived runtime branch.
4. Freeze scope before coding.
5. Implement only that batch.
6. Run Flutter, Firebase Rules and Cloud Functions checks as applicable.
7. Build with the permanent Android signing identity.
8. Install using update mode (`adb install -r`), never uninstall/wipe for normal upgrades.
9. Preserve package `com.nearmeu.nearmeu` and monotonically increasing versionCode.
10. Physically test only the focused new behavior plus necessary regression smoke checks.
11. Record commit/artifact/hash/workflow evidence and owner decision.
12. Merge through a passing PR.
13. Update recovery docs and promote `stable/official-recoverable-base`.
14. Sync `F:\NearMeU` back to promoted `main`.

## Current accepted starting point

The current promoted recovery base remains Batch 05 until Batch 06 final merge/recovery promotion completes:

- Final promoted Batch 05 main/recovery: `3b749c8d7a320b71446245f99c694fdf85d9ccc4`
- Version: `1.0.8+9`
- Package: `com.nearmeu.nearmeu`

## Completed batches

- Batch 00 — Governance, roadmap and decision freeze — accepted.
- Batch 01 — Chat reliability and message-state truth — accepted.
- Batch 02 — Photo/video/voice-message reliability — accepted.
- Batch 03 — Local-first persistence and seven-day delivery cloud — accepted.
- Batch 04 — Clear Chat and deletion semantics — accepted/promoted.
- Batch 05 — Identity, account close and reactivation — accepted/promoted.

## Accepted / promotion pending

### Batch 06 — Premium entitlement foundation

Owner physically accepted the focused Batch 06 behavior on 2026-08-01.

Accepted runtime evidence:

- PR: `#96`
- Tested runtime: `52fe6a52ad117e9eccb922e535b9d6752af7e695`
- Version: `1.0.9+10`
- Build #40 / run `30706204824`: PASS
- Quality #439 / run `30706204828`: PASS
- Signed debug APK SHA-256: `2df1a743c313ec8b90b73d52677e2de2360b02c3858e1f9dbd1735c1534a016f`
- Signed release APK SHA-256: `4aac231c92283884cc8af1a5d88ad517c29ae716c7e541d9aa6a8be85d9f4b72`
- Production `getMyPremiumEntitlement` available and tested.
- Production `sendPrivateMediaMessage` updated with Premium enforcement.
- Free text remained usable.
- Free outbound mic/photo/video controls remained visible and correctly locked.
- Existing received/local media remained available.
- Stale-token `UNAUTHENTICATED` behavior was fixed with one forced Firebase ID-token refresh/retry and physically retested successfully.

Batch 06 still requires acceptance-head CI, PR merge, final recovery documentation and recovery-branch promotion before Batch 07 runtime code begins.

## Next batch after promotion

### Batch 07 — Six-month automatic Premium backup and restore

Planned scope remains:

- automatic Premium backup/recovery window up to six months;
- use Batch 06 trusted entitlement truth rather than a local Premium flag;
- preserve Clear Chat / deletion tombstone semantics so intentionally cleared/deleted content cannot resurrect;
- define restore eligibility and retained backup lifecycle precisely before runtime implementation;
- do not mix profile sharing, calling or owner-admin entitlement controls into this batch.

## Later batches

- Batch 08 — Profile sharing and deep-link recovery
- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — Owner-only Premium administration
- Batch 12 — Full regression and Play Store readiness

## Recovery-base movement rule

`main` is merged development truth. `stable/official-recoverable-base` is the last fully accepted runtime/documentation truth. It moves only after CI, permanent signing, physical owner acceptance, required production actions and final documentation are complete.
