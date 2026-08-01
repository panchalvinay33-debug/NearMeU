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
| 02 | Photo/video/voice-message reliability | ACCEPTED | `batch/02-media-reliability` | Yes | Promoted official base after docs merge |
| 03 | Local-first persistence and seven-day delivery cloud | PLANNED | — | Yes | Next batch |
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
APK filename: NearMeU-Batch-02-v1.0.5-6-Signed.apk
APK SHA-256: b355c854f210aea3787b937a46ab6714f60e18f7acf471779a4daf2655f43d76
Artifact ID: 8814680642
Artifact digest: sha256:929f66eab59f188bd57f4a8ab586f9bacea2185093041b631e1b8df4f0960bd6
Android package: com.nearmeu.nearmeu
Version: 1.0.5+6
Build workflow: 30687614764 / #20 — passed
Quality workflow: 30687614766 / #411 — passed
Permanent signing certificate verification: passed
Cloud Functions checks: passed
Firebase rules tests: passed
Physical result: working
Owner decision: ACCEPTED on 2026-08-01
Next batch: 03 Local-first persistence and seven-day delivery cloud
```

## Batch 02 accepted behavior

- Photo/video/voice send/download/play/open paths work through the accepted signed build.
- Local media is integrity-checked before reuse.
- Corrupt or partial files are removed instead of opened.
- Failed downloads expose retry behavior.
- Pending private media outbox records recover on authentication and app resume.
- Voice confirmation retries ambiguous outcomes and verifies the exact Firestore message before declaring failure.
- Existing Batch 01 tick behavior remains part of the accepted base.

## Non-negotiable rule

Every later runtime batch starts from the promoted Batch 02 official base. A later batch may not replace the recovery branch until CI, signed build, physical testing, owner acceptance and documentation are complete.
