# NearMeU Test Batch Register

Last updated: 2026-07-31

This register is updated after every accepted or rejected batch. It must never claim physical acceptance without the APK/AAB hash, device evidence and owner decision.

## Status legend

- `PLANNED` — scope approved; work not started.
- `IN_PROGRESS` — active short-lived branch exists.
- `CODE_COMPLETE` — implementation finished; required testing incomplete.
- `TEST_FAILED` — one or more acceptance gates failed; remains on same branch.
- `OWNER_REVIEW` — all required evidence is ready for owner acceptance.
- `ACCEPTED` — merged and accepted; recovery-base status separately recorded.
- `DEFERRED` — intentionally postponed.

## Batch table

| Batch | Title | Status | Branch | Runtime change | Physical APK test required | Recovery-base movement |
|---|---|---|---|---:|---:|---:|
| 00 | Governance, roadmap and decision freeze | IN_PROGRESS | `batch/00-governance-roadmap-freeze` | No | No | No |
| 01 | Chat reliability and message-state truth | PLANNED | — | Yes | Yes, two-account/two-device | After merged-main acceptance |
| 02 | Photo/video/voice-message reliability | PLANNED | — | Yes | Yes, two-device | After merged-main acceptance |
| 03 | Local-first persistence and seven-day delivery cloud | PLANNED | — | Yes | Yes | After merged-main acceptance |
| 04 | Clear Chat and deletion semantics | PLANNED | — | Yes | Yes, reinstall/multi-device | After merged-main acceptance |
| 05 | Identity, account close and reactivation | PLANNED | — | Yes | Yes, two-account | After merged-main acceptance |
| 06 | Premium entitlement foundation | PLANNED | — | Yes | Yes | After merged-main acceptance |
| 07 | Six-month automatic Premium backup and restore | PLANNED | — | Yes | Yes, reinstall/phone-change | After merged-main acceptance |
| 08 | Profile sharing and deep-link recovery | PLANNED | — | Yes | Yes, install/no-install | After merged-main acceptance |
| 09 | Agora audio calling | PLANNED | — | Yes | Yes, two-device | After merged-main acceptance |
| 10 | Agora video calling | PLANNED | — | Yes | Yes, two-device | After merged-main acceptance |
| 11 | Owner-only Premium administration | PLANNED | — | Yes | Yes | After merged-main acceptance |
| 12 | Full regression and Play Store readiness | PLANNED | — | Yes/release | Yes, release matrix | New release base after approval |

## Batch 00 record

```text
Batch ID: 00
Title: Governance, roadmap and decision freeze
Branch: batch/00-governance-roadmap-freeze
Base commit: c414810c8a483f44debb8ba67fce3156c8718d7f
Runtime change: none
Firebase deployment: none
Accepted runtime commit remains: f9bc38572c715a017c8b261a5d805aa125ffe7a5
Accepted APK SHA-256 remains: 587CD1B328A1CAEB659A0C5D0604609C5E6A381B61EFC6D0ACD9D3C2B1BDE00C
Required checks:
- canonical documents created/updated
- JSON manifest validation
- links/path review
- branch diff confirms documentation/config only
Physical APK test: not required because runtime is unchanged
Owner decision: pending
Merged to main: no
Recovery branch moved: no
Next batch after acceptance: 01 Chat reliability and message-state truth
```

## Current observed app state from the latest owner demo

The latest supplied demo is evidence of visible flows, not a complete acceptance test. It showed working or reachable UI for:

- Google sign-in and onboarding.
- Nearby/search/filter.
- One-to-one chat.
- Text, photo/video preparation and voice-message playback paths.
- Profile, block, settings and blocked-users screens.
- Owner admin dashboard, user management and reports.

Observed gaps requiring later batches:

- Current tick presentation appears to distinguish sent and seen, not a separately acknowledged delivered state.
- Unread/read behavior still requires controlled two-device testing.
- Media preparation needs clearer progress, retry and cancellation behavior.
- Nearby loading requires timeout/offline/retry polish.
- Premium, automatic six-month recovery, seven-day delivery-cloud cleanup, Clear Chat purge, account-close reactivation, profile sharing and Agora calling are approved/planned rather than accepted runtime features.

## Required completion block for future batches

Copy this section when a batch reaches owner review:

```text
Batch ID:
Title:
Branch:
Base commit:
Final branch commit:
Changed files:
Pull request:
Merged main commit:
Recovery branch commit:
APK/AAB filename:
APK/AAB SHA-256:
Signing certificate identity:
Workflow run(s):
Test device(s):
Android version(s):
Test account(s):
Automated tests:
Flutter analyze:
Firebase rules tests:
Cloud Functions tests:
Physical scenarios tested:
Failures found and fixed:
Known limitations:
Owner decision:
Documentation updated:
Temporary branch deleted:
Next batch:
```

## Non-negotiable rule

A later runtime batch cannot be marked `IN_PROGRESS` while the current runtime batch is still awaiting required testing or owner acceptance. Documentation preparation may occur only when it does not alter or distract from the active runtime acceptance gate.