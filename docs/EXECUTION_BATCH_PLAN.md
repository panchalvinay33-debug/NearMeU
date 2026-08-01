# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-01

Every runtime change is one focused batch. A later batch starts only after automated tests, signed build, focused physical acceptance, owner approval, merge and recovery promotion are complete.

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
10. Merge through passing PR, update recovery docs, promote recovery branch, then sync `F:\NearMeU`.

## Current accepted starting point

Batch 06 is the accepted runtime base:

- Runtime merge: `2eea2d3fc0583ace77526bae9a918c940e470d24`
- Tested runtime: `52fe6a52ad117e9eccb922e535b9d6752af7e695`
- PR: `#96`
- Version: `1.0.9+10`
- Build #40 / run `30706204824`: PASS
- Quality #439 / run `30706204828`: PASS
- Acceptance-head Build #44 / run `30709123869`: PASS
- Acceptance-head Quality #443 / run `30709123867`: PASS
- Owner physical acceptance: PASS on 2026-08-01
- Production `getMyPremiumEntitlement` and Premium-enforced `sendPrivateMediaMessage`: PASS

## Completed batches

Batches 00 through 06 are accepted. Batch 06 adds trusted private Premium entitlement truth, server-side outbound media/voice authorization, visible Free-user locks, and stale-token refresh/retry hardening while preserving Free text and incoming/local media.

## Next batch

### Batch 07 — Six-month automatic Premium backup and restore

Frozen scope:

- automatic eligible Premium recovery retention for up to six months;
- use Batch 06 trusted entitlement truth, never a local Premium flag;
- eligible recovery may include text, downloaded sent/received photo/video/voice, timestamps, replies and conversation context;
- future call-history metadata may be eligible, but actual audio/video calls are never recorded or backed up;
- Clear Chat permanently removes that user's recoverable copy and must prevent resurrection;
- permanently deleted/cleared content must not return after reinstall/restore;
- Premium expiry does not immediately erase items whose six-month retention was validly assigned while Premium was active;
- restore must avoid duplicate messages/media;
- do not mix profile sharing, calling or owner-admin entitlement mutation into Batch 07.

## Later batches

- Batch 08 — Profile sharing and deep-link recovery
- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — Owner-only Premium administration
- Batch 12 — Full regression and Play Store readiness

## Recovery-base movement rule

`stable/official-recoverable-base` moves only after CI, signing, physical acceptance, required production actions and final documentation are complete.
