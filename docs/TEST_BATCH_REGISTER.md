# NearMeU Test Batch Register

Last updated: 2026-08-01

Physical acceptance requires a signed artifact, checksum, device evidence and owner decision.

## Status legend

- `PLANNED` — scope approved; work not started.
- `IN_PROGRESS` — active short-lived branch exists.
- `TEST_FAILED` — one or more acceptance gates failed.
- `OWNER_REVIEW` — evidence ready for owner decision.
- `ACCEPTED` — merged, documented and eligible as recovery base.
- `DEFERRED` — intentionally postponed.

## Batch table

| Batch | Title | Status | Branch | Runtime change | Recovery-base status |
|---|---|---|---|---:|---|
| 00 | Governance, roadmap and decision freeze | ACCEPTED | merged | No | Documentation foundation |
| 01 | Chat reliability and message-state truth | ACCEPTED | `batch/01-chat-reliability` | Yes | Superseded |
| 02 | Photo/video/voice-message reliability | ACCEPTED | `batch/02-media-reliability` | Yes | Superseded by Batch 03 |
| 03 | Local-first persistence and seven-day delivery cloud | ACCEPTED | `batch/03-local-first-seven-day-cloud` | Yes | Promoted official base |
| 04 | Clear Chat and deletion semantics | IN_PROGRESS | `batch/04-clear-chat-deletion-semantics` | Yes | Testing/evidence pending |
| 05 | Identity, account close and reactivation | PLANNED | — | Yes | After acceptance |
| 06 | Premium entitlement foundation | PLANNED | — | Yes | After acceptance |
| 07 | Six-month automatic Premium backup and restore | PLANNED | — | Yes | After acceptance |
| 08 | Profile sharing and deep-link recovery | PLANNED | — | Yes | After acceptance |
| 09 | Agora audio calling | PLANNED | — | Yes | After acceptance |
| 10 | Agora video calling | PLANNED | — | Yes | After acceptance |
| 11 | Owner-only Premium administration | PLANNED | — | Yes | After acceptance |
| 12 | Full regression and Play Store readiness | PLANNED | — | Yes/release | Release base after approval |

## Batch 01 acceptance record

- PR: `#86`
- Merged runtime SHA: `9b4b5a03464240c5bfba449a2a0b8ceda1712c1f`
- Version: `1.0.4+5`
- APK SHA-256: `63866e7e0519a2f00ac81c5df811b26c4ba4ea04e69ab2f61a3c42a06f07fee7`
- Result: sent/delivered/read tick truth physically accepted.

## Batch 02 acceptance record

- PR: `#88`
- Merged runtime SHA: `d7a8c800d48beb7f646fb4d76d0afd7fbfeafa56`
- Version: `1.0.5+6`
- APK SHA-256: `b355c854f210aea3787b937a46ab6714f60e18f7acf471779a4daf2655f43d76`
- Result: photo/video/voice reliability physically accepted.

## Batch 03 acceptance record

```text
Batch ID: 03
Title: Local-first persistence and seven-day delivery cloud
Status: ACCEPTED
Branch: batch/03-local-first-seven-day-cloud
Base: 2c54f6b6677213ac452043d86c0248e5bbfbdd58
Tested runtime commit: 72e25450a2df38cf44183d994a13f6acd61369e5
Final evidence head: 075c7e6d4abb05f40e4ed8b116aa20eddecf2c09
Pull request: #90
Merged main runtime commit: e98bd0ebe86dad1f689723a9e96f35095a015a7b
Final documented/recovery commit: f487be76f958c06966e15f3db9cbbec65f5cfa9c
Version: 1.0.6+7
Android package: com.nearmeu.nearmeu
APK filename: NearMeU-Batch-03-v1.0.6-7-Signed.apk
APK SHA-256: a5e1c9b9a89e83b39023b95a8b1c8c2fd8c33e8cd120ad63c55a68cfe8c7d024
Final artifact ID: 8816552470
Final artifact digest: sha256:ce88dcebc0c38bcae77e32596f22a37d54a2f11a5ef84176282c624c8789e7d1
Owner physical acceptance: PASSED on 2026-08-01
Production retention deployment: PASSED
Owner decision: ACCEPTED on 2026-08-01
```

## Batch 04 in-progress record

```text
Batch ID: 04
Title: Clear Chat and deletion semantics
Status: IN_PROGRESS
Branch: batch/04-clear-chat-deletion-semantics
Base: f487be76f958c06966e15f3db9cbbec65f5cfa9c
Target version: 1.0.7+8
Android package: com.nearmeu.nearmeu
Required new backend: clearPrivateChat(asia-south1)
Production backend deployment: pending CI proof before deployment
Signed APK: pending CI
Physical owner test: pending one focused coordinated pass
```

Implemented scope under test:

- trusted per-user Clear Chat cutoff stored at `clearStates.<uid>.clearedAt`;
- Clear Chat removes local encrypted rows and referenced local media through the exact cutoff;
- cleared history stays hidden after restart/sync and chat list remains hidden until newer post-clear activity;
- the other participant is unaffected by Clear Chat;
- Delete for Me removes the actor's local row/media and no longer recreates an already-expired cloud message stub;
- remote `deletedFor` updates are reconciled into local deletion while available;
- Delete for Everyone uses the existing trusted 60-minute unsend backend and now explicitly detaches local media/content metadata;
- UI exposes `Clear Chat` in the chat three-dot menu and names sender unsend as `Delete for everyone`;
- clear operation is blocked while a send/recording is active to avoid ambiguous destructive boundaries.

Focused physical matrix: [`BATCH_04_PHYSICAL_TEST.md`](BATCH_04_PHYSICAL_TEST.md).

## Canonical local workspace rule

The active owner working copy is `F:\NearMeU`. After every accepted/promoted batch it must be synchronized to the promoted `main` / `stable/official-recoverable-base` state. Downloads clones and `F:\NearMeU-OLD` are not the active project.

## Current gate

Batch 04 must pass CI, permanently signed `1.0.7+8` APK build, production `clearPrivateChat` deployment, one focused physical-device pass and owner acceptance before merge/promotion. Batch 03 remains the official recovery base until then.
