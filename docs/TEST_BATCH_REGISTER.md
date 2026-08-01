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
| 03 | Local-first persistence and seven-day delivery cloud | OWNER_REVIEW | `batch/03-local-first-seven-day-cloud` | Yes | Physical accepted; backend deployment remains before promotion |
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

## Batch 03 owner-review record

```text
Batch ID: 03
Title: Local-first persistence and seven-day delivery cloud
Status: OWNER_REVIEW
Branch: batch/03-local-first-seven-day-cloud
Base: 2c54f6b6677213ac452043d86c0248e5bbfbdd58
Final tested runtime commit: 72e25450a2df38cf44183d994a13f6acd61369e5
Current branch head after evidence-only commits: 7901ebd0a14826ca38b0fef9cf88123b6c34f9ce
Pull request: #90 (draft)
Test version: 1.0.6+7
Android package: com.nearmeu.nearmeu
APK filename: NearMeU-Batch-03-v1.0.6-7-Signed.apk
APK SHA-256: a5e1c9b9a89e83b39023b95a8b1c8c2fd8c33e8cd120ad63c55a68cfe8c7d024
Original artifact ID: 8815490869
Original artifact digest: sha256:36e57413b16d1b7c39e29ae0cbcd266fc268b0c08e5bdd669c93dd9499fa8b2a
Latest evidence artifact ID: 8815819144
Latest evidence artifact digest: sha256:aaeaf015ea8816b60b385f3f484b56abfe67aef3bb7e04eaf2015a425b920a1a
Build workflow: 30691064361 / #23 — passed
Quality workflow: 30691064349 / #416 — passed
Permanent signing certificate SHA-1: 7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55
Permanent signing certificate SHA-256: B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B
Flutter analyze/tests: passed
Cloud Functions tests: passed
Firebase rules tests: passed
Owner physical acceptance: PASSED on 2026-08-01
Direct update without uninstall/data loss: passed
Login/history/app-state preservation: passed
Offline/restart local history: passed
Downloaded photo/video/voice local reuse: passed
Batch 01 tick regression: passed
Batch 02 media regression: passed
Required retention deployment: pending
Recovery branch movement: forbidden until backend deployment and final acceptance completion
```

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
- deploy the updated Firebase retention functions to project `nearmeu-e82c7`
- verify the production deployment succeeds
- then merge and promote Batch 03 through the normal documentation/recovery-base flow

## Non-negotiable rule

Every later runtime batch starts from the promoted Batch 02 official base until Batch 03 is accepted. Batch 03 may not replace `stable/official-recoverable-base` until CI, signed build, required backend deployment, physical testing, owner acceptance and final documentation are complete.
