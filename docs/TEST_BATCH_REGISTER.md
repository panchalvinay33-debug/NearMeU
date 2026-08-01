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
| 01 | Chat reliability and message-state truth | ACCEPTED | `batch/01-chat-reliability` | Yes | Superseded by accepted Batch 02 base |
| 02 | Photo/video/voice-message reliability | ACCEPTED | `batch/02-media-reliability` | Yes | Promoted official base |
| 03 | Local-first persistence and seven-day delivery cloud | IN_PROGRESS | `batch/03-local-first-seven-day-cloud` | Yes | Batch 02 remains recovery base until acceptance |
| 04 | Clear Chat and deletion semantics | PLANNED | — | Yes | After acceptance |
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

```text
Batch ID: 02
Title: Photo/video/voice-message reliability
Branch: batch/02-media-reliability
Base documented recovery commit: f75e6131f43bf0e0b60c172885b4ec460731237a
Final branch commit: bbed8998040099202e50e26c62782a04b6b9fe04
Pull request: #88
Merged main commit: d7a8c800d48beb7f646fb4d76d0afd7fbfeafa56
Final documented/recovery commit: 2c54f6b6677213ac452043d86c0248e5bbfbdd58
APK filename: NearMeU-Batch-02-v1.0.5-6-Signed.apk
APK SHA-256: b355c854f210aea3787b937a46ab6714f60e18f7acf471779a4daf2655f43d76
Android package: com.nearmeu.nearmeu
Version: 1.0.5+6
Build workflow: 30687614764 / #20 — passed
Quality workflow: 30687614766 / #411 — passed
Physical result: working
Owner decision: ACCEPTED on 2026-08-01
```

## Batch 03 working record

```text
Batch ID: 03
Title: Local-first persistence and seven-day delivery cloud
Status: IN_PROGRESS
Branch: batch/03-local-first-seven-day-cloud
Base: 2c54f6b6677213ac452043d86c0248e5bbfbdd58
Test version: 1.0.6+7
Recovery branch movement: forbidden until physical acceptance

Implemented in current branch:
- cloud delivery expiry is explicit at message-model level
- remote media is never advertised as downloadable at or after cloudExpiresAt
- a valid local media path remains independent of cloud expiry
- encrypted local chat history remains the UI source when Firestore history has been purged
- backend retention purge now deletes the Firestore message only after its private Storage object is safely deleted or confirmed absent
- unsafe/unexpected media paths are refused instead of deleting outside the scoped private-message folder
- Storage deletion failures defer Firestore message deletion for a later scheduled retry, preventing silent orphaned media
- voice metadata is represented correctly in post-purge chat preview fallback
- focused Flutter retention tests added

Acceptance still required:
- final quality gate and signed APK build
- Firebase deployment of updated retention function before expiry testing
- direct update over accepted 1.0.5+6 without uninstall/data loss
- local text remains visible after cloud copy is removed/expired
- downloaded photo/video/voice remains usable locally after cloud expiry
- media not downloaded before expiry is shown unavailable rather than as a broken download
- offline app restart still shows local history
- cloud cleanup must not delete local files
- Batch 01 tick behavior and Batch 02 media behavior must remain regression-safe
- owner acceptance
```

## Non-negotiable rule

Every later runtime batch starts from the promoted Batch 02 official base until Batch 03 is accepted. Batch 03 may not replace `stable/official-recoverable-base` until CI, signed build, required backend deployment, physical testing, owner acceptance and final documentation are complete.
