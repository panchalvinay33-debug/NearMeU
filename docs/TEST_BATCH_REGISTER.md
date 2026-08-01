# NearMeU Test Batch Register

Last updated: 2026-08-01

This register is updated after every accepted or rejected batch. Physical acceptance requires a signed artifact, checksum, device evidence and owner decision.

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
| 01 | Chat reliability and message-state truth | ACCEPTED | `batch/01-chat-reliability` | Yes | Promoted official base |
| 02 | Photo/video/voice-message reliability | IN_PROGRESS | `batch/02-media-reliability` | Yes | Must remain on Batch 01 base until physical acceptance |
| 03 | Local-first persistence and seven-day delivery cloud | PLANNED | — | Yes | After acceptance |
| 04 | Clear Chat and deletion semantics | PLANNED | — | Yes | After acceptance |
| 05 | Identity, account close and reactivation | PLANNED | — | Yes | After acceptance |
| 06 | Premium entitlement foundation | PLANNED | — | Yes | After acceptance |
| 07 | Six-month automatic Premium backup and restore | PLANNED | — | Yes | After acceptance |
| 08 | Profile sharing and deep-link recovery | PLANNED | — | Yes | After acceptance |
| 09 | Agora audio calling | PLANNED | — | Yes | After acceptance |
| 10 | Agora video calling | PLANNED | — | Yes | After acceptance |
| 11 | Owner-only Premium administration | PLANNED | — | Yes | After acceptance |
| 12 | Full regression and Play Store readiness | PLANNED | — | Yes/release | Release base after approval |

## Batch 00 record

- Status: accepted documentation/governance foundation.
- Runtime base was intentionally unchanged.
- Merge commit: `0aa563ba1b651a1c7431da1f111f14ed4bbc6640`.

## Batch 01 acceptance record

```text
Batch ID: 01
Title: Chat reliability and message-state truth
Branch: batch/01-chat-reliability
Base commit: 0aa563ba1b651a1c7431da1f111f14ed4bbc6640
Final branch commit: 22af597d63ffedebe701389d671c9f1f345edae7
Pull request: #86
Merged main commit: 9b4b5a03464240c5bfba449a2a0b8ceda1712c1f
APK filename: NearMeU-Batch-01-v1.0.4-5-Signed.apk
APK SHA-256: 63866e7e0519a2f00ac81c5df811b26c4ba4ea04e69ab2f61a3c42a06f07fee7
Android package: com.nearmeu.nearmeu
Version: 1.0.4+5
Build workflow: 30683308079 — passed
Quality workflow: 30683308083 — passed
Firebase Functions deployment: passed on 2026-08-01
Direct update install: adb install -r — success
Uninstall/data wipe: not required
Login preserved: yes
Encrypted chat history preserved: yes
App state preserved: yes
Physical test: two accounts/two-device behavior
Single tick/server accepted: passed
Grey double tick/receiver synchronized: passed
Blue double tick/receiver read: passed
Receiver reply/two-way messaging: passed
Failures found and fixed: callable-only receipt dependency, missing resilient read-state fallback, listener resume/coverage gaps
Known limitations: media reliability remains Batch 02 scope
Owner decision: ACCEPTED on 2026-08-01 at approximately 10:26 IST
Next batch: 02 Photo/video/voice-message reliability
```

## Batch 01 accepted behavior

- Single tick means the server accepted the outgoing message.
- Grey double tick means the receiver device/app synchronized or observed it.
- Blue double tick means the receiver opened/read the chat.
- Trusted chat read-state timestamps provide safe convergence for legacy/local-history messages.
- Existing application identity, signing compatibility, login and encrypted history survive direct updates.

## Batch 02 working record

```text
Batch ID: 02
Title: Photo/video/voice-message reliability
Status: IN_PROGRESS
Branch: batch/02-media-reliability
Base: accepted Batch 01 documented recovery base f75e6131f43bf0e0b60c172885b4ec460731237a
Pull request: #88 (draft)
Test version: 1.0.5+6
Recovery branch movement: forbidden until physical acceptance

Implemented so far:
- voice send confirmation now retries ambiguous callable outcomes and verifies the exact Firestore message before declaring failure
- ambiguous voice confirmation preserves the local pending outbox instead of deleting a potentially successful upload
- definitive/pre-upload failures clean pending local/cloud records
- voice local files are size/integrity checked before reuse; invalid files are removed and redownloaded
- voice interrupted-download partial files are cleaned and valid on-disk destination files can repair local database state
- photo/video local media is validated against declared size before display/reuse
- corrupt/zero-length photo/video local files and broken thumbnails are discarded rather than blindly opened
- global signed-in lifecycle now retries all pending private media outbox records on authentication and every app resume, not only when a specific chat is reopened
- the existing generic media outbox recovery handles image, video and voice records because confirmation uses each record's message type and storage path

Still required before owner review:
- latest CI must pass after final Batch 02 changes
- signed APK artifact and SHA-256 must be recorded
- direct update over accepted 1.0.4+5 must succeed without uninstall/data loss
- physical two-device photo send/download/open/restart test
- physical two-device video send/download/play/restart test
- physical two-device voice send/download/play/restart test
- interrupted/offline/reconnect recovery test
- no duplicate media messages after retry/resume
- owner acceptance
```

## Non-negotiable rule

Batch 02 and every later runtime batch must start from the promoted Batch 01 official base. A later batch may not replace the recovery branch until its own CI, signed build, physical testing, owner acceptance and documentation are complete.
