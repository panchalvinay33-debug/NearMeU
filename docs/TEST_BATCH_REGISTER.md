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
| 02 | Photo/video/voice-message reliability | ACCEPTED | `batch/02-media-reliability` | Yes | Superseded |
| 03 | Local-first persistence and seven-day delivery cloud | ACCEPTED | `batch/03-local-first-seven-day-cloud` | Yes | Superseded by Batch 04 |
| 04 | Clear Chat and deletion semantics | ACCEPTED | `batch/04-clear-chat-deletion-semantics` | Yes | Promoted official base |
| 05 | Identity, account close and reactivation | ACCEPTED | `batch/05-identity-account-close-reactivation` | Yes | Awaiting merge/final promotion |
| 06 | Premium entitlement foundation | PLANNED | — | Yes | Next batch after Batch 05 promotion |
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
Tested runtime commit: 72e25450a2df38cf44183d994a13f6acd61369e5
Pull request: #90
Merged main runtime commit: e98bd0ebe86dad1f689723a9e96f35095a015a7b
Final documented/recovery commit: f487be76f958c06966e15f3db9cbbec65f5cfa9c
Version: 1.0.6+7
APK SHA-256: a5e1c9b9a89e83b39023b95a8b1c8c2fd8c33e8cd120ad63c55a68cfe8c7d024
Owner decision: ACCEPTED
```

## Batch 04 acceptance record

```text
Batch ID: 04
Title: Clear Chat and deletion semantics
Status: ACCEPTED
Branch: batch/04-clear-chat-deletion-semantics
Base: f487be76f958c06966e15f3db9cbbec65f5cfa9c
Tested runtime commit: f22b36690b7ca65828ce2db809a89abe9931f83e
Physical acceptance evidence head: c98f304f5bd4525315d8f5c6c558e2d0dca98b5d
Pull request: #92
Merged main runtime commit: d387b5cf8db7d9e792673ada4dd1c1d2958c7aee
Final documented/recovery commit: c0a734e3dfbbab61b5c1b008df4e3f09bb011556
Version: 1.0.7+8
Android package: com.nearmeu.nearmeu
Tested APK SHA-256: 24e770e3b09cfcb2608b8a8283405cef282f62a4832a3e67fd3a625a2bd2deb8
Production clearPrivateChat(asia-south1) deployment: PASS
Focused physical owner test: PASS
Owner decision: ACCEPTED on 2026-08-01
```

## Batch 05 acceptance record

```text
Batch ID: 05
Title: Identity, account close and reactivation
Status: ACCEPTED
Branch: batch/05-identity-account-close-reactivation
Base: c0a734e3dfbbab61b5c1b008df4e3f09bb011556
Tested runtime commit: d2868b97dc931a49f625f4711db4b555fecd34ec
Pull request: #94
Version: 1.0.8+9
Android package: com.nearmeu.nearmeu
Build #33 / run 30699307402: PASS
Quality #430 / run 30699307401: PASS
Recoverable artifact ID: 8818404060
Recoverable artifact digest: sha256:70505abc00881695754c70684ae4140ab05224c1c424d242d6cdc9d11e20e94c
Tested signed debug APK SHA-256: c3371eb86c73a090b311c4d42656d8eaf799025aa04cd56da3bc6f51faeaf406
Release artifact ID: 8818505561
Release APK SHA-256: e648ece943692ae4d7bcc083088f8ecbdde91a5c1fb892344076bff0bf8c1966
Direct-update/history preservation: PASS
Closed account neutral unavailable state: PASS
Closed-account message authorization refusal: PASS
Same-account reactivation/profile recreation: PASS
Conversation continuity after reactivation: PASS
Sign Out / Close Account / Permanent Delete separation: PASS
Owner decision: ACCEPTED on 2026-08-01
```

Detailed focused physical matrix: [`BATCH_05_PHYSICAL_TEST.md`](BATCH_05_PHYSICAL_TEST.md).

## Canonical local workspace rule

The active owner working copy is `F:\NearMeU`. After every accepted/promoted batch it must be synchronized to the promoted `main` / `stable/official-recoverable-base` state. Downloads clones and `F:\NearMeU-OLD` are not the active project.

## Current gate

Batch 05 is owner-accepted. Merge PR #94 only after the acceptance-head CI is green, then complete final acceptance documentation and fast-forward `stable/official-recoverable-base`. Batch 06 starts only from that promoted Batch 05 base.
