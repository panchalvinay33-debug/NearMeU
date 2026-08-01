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
| 04 | Clear Chat and deletion semantics | ACCEPTED | `batch/04-clear-chat-deletion-semantics` | Yes | Promoted official base after docs merge |
| 05 | Identity, account close and reactivation | PLANNED | — | Yes | Next batch |
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
Version: 1.0.7+8
Android package: com.nearmeu.nearmeu
Tested APK filename: NearMeU-Batch-04-v1.0.7-8-Signed.apk
Tested APK SHA-256: 24e770e3b09cfcb2608b8a8283405cef282f62a4832a3e67fd3a625a2bd2deb8
Tested artifact ID: 8817336599
Tested artifact digest: sha256:6a012c299547e7b32f9f76e5c1ece24e2b4110111bae40289372b1624ccbb39a
Final docs-head recoverable artifact ID: 8817642243
Final docs-head recoverable artifact digest: sha256:6bbb921fc7f115bd84aaa3ce1979da65271ea77f4cd129b787120096e3bc10d3
Build #27 / run 30695802197: PASS
Quality #422 / run 30695802185: PASS
Docs-head Build #28 / run 30696835582: PASS
Docs-head Quality #423 / run 30696835612: PASS
Production clearPrivateChat(asia-south1) deployment: PASS
Focused physical owner test: PASS
Clear Chat after production deployment: PASS
Delete for Me: PASS
Delete for Everyone: PASS
Tick regression: PASS
Owner decision: ACCEPTED on 2026-08-01
```

Accepted Batch 04 behavior:

- authoritative per-user Clear Chat cutoff at `clearStates.<uid>.clearedAt`;
- encrypted local rows and referenced local media removed through the clear cutoff;
- cleared history remains hidden after restart/sync once clear state is observed;
- chat remains absent from actor list until newer post-clear activity;
- other participant remains unaffected by actor Clear Chat;
- Delete for Me does not recreate an expired delivery-cloud stub;
- Delete for Everyone retains trusted sender-only 60-minute semantics and local media detachment;
- production `clearPrivateChat` callable deployed successfully.

Focused physical matrix: [`BATCH_04_PHYSICAL_TEST.md`](BATCH_04_PHYSICAL_TEST.md).

## Canonical local workspace rule

The active owner working copy is `F:\NearMeU`. After every accepted/promoted batch it must be synchronized to the promoted `main` / `stable/official-recoverable-base` state. Downloads clones and `F:\NearMeU-OLD` are not the active project.

## Current gate

Batch 04 is accepted and merged. Final acceptance documentation must merge and `stable/official-recoverable-base` must then fast-forward to that exact docs merge commit. Batch 05 may start only from the promoted Batch 04 base.
