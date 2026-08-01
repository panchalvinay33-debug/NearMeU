# NearMeU Test Batch Register

Last updated: 2026-08-01

Physical acceptance requires a signed artifact, checksum, device evidence and owner decision.

## Batch table

| Batch | Title | Status | Recovery-base status |
|---|---|---|---|
| 00 | Governance, roadmap and decision freeze | ACCEPTED | Documentation foundation |
| 01 | Chat reliability and message-state truth | ACCEPTED | Superseded |
| 02 | Photo/video/voice-message reliability | ACCEPTED | Superseded |
| 03 | Local-first persistence and seven-day delivery cloud | ACCEPTED | Superseded |
| 04 | Clear Chat and deletion semantics | ACCEPTED | Superseded |
| 05 | Identity, account close and reactivation | ACCEPTED | Superseded by Batch 06 |
| 06 | Premium entitlement foundation | ACCEPTED | Promoted official base |
| 07 | Six-month automatic Premium backup and restore | PLANNED NEXT | Starts after Batch 06 promotion docs merge |
| 08 | Profile sharing and deep-link recovery | PLANNED | Later |
| 09 | Agora audio calling | PLANNED | Later |
| 10 | Agora video calling | PLANNED | Later |
| 11 | Owner-only Premium administration | PLANNED | Later |
| 12 | Full regression and Play Store readiness | PLANNED | Release-readiness gate |

## Batch 05 acceptance record

```text
Batch ID: 05
Status: ACCEPTED
Tested runtime commit: d2868b97dc931a49f625f4711db4b555fecd34ec
Pull request: #94
Merged main runtime commit: 44143f612cbf8b7adf6d591abe74aac2c6397704
Final promoted main/recovery commit: 3b749c8d7a320b71446245f99c694fdf85d9ccc4
Version: 1.0.8+9
Owner decision: ACCEPTED on 2026-08-01
```

## Batch 06 acceptance record

```text
Batch ID: 06
Title: Premium entitlement foundation
Status: ACCEPTED
Base: 3b749c8d7a320b71446245f99c694fdf85d9ccc4
Tested runtime commit: 52fe6a52ad117e9eccb922e535b9d6752af7e695
Acceptance evidence head: a626a501db3b1d24573f6002087b2f0d88b16ce3
Pull request: #96
Merged main runtime commit: 2eea2d3fc0583ace77526bae9a918c940e470d24
Version: 1.0.9+10
Android package: com.nearmeu.nearmeu
Build #40 / run 30706204824: PASS
Quality #439 / run 30706204828: PASS
Acceptance-head Build #44 / run 30709123869: PASS
Acceptance-head Quality #443 / run 30709123867: PASS
Recoverable artifact ID: 8820525497
Recoverable artifact digest: sha256:7a6023c00bc328438efa4135f411286ae98c39485ff2c35f4385697eb78ea4e7
Tested signed debug APK SHA-256: 2df1a743c313ec8b90b73d52677e2de2360b02c3858e1f9dbd1735c1534a016f
Signed release artifact ID: 8820623151
Signed release artifact digest: sha256:0998f97e18470ba2602c5dd84ae173c560f31b86c55f832e1af43200e63af65c
Signed release APK SHA-256: 4aac231c92283884cc8af1a5d88ad517c29ae716c7e541d9aa6a8be85d9f4b72
Production getMyPremiumEntitlement deployment: PASS
Production sendPrivateMediaMessage update: PASS
Direct-update/history/media preservation: PASS
Free text messaging: PASS
Free outbound voice lock: PASS
Free outbound photo/video lock: PASS
Prior received/local media remains accessible: PASS
Owner decision: ACCEPTED on 2026-08-01
```

Accepted scope includes trusted private Premium entitlement truth, server-side outbound media/voice authorization, visible Free-user locks, stale-token refresh/retry hardening, and preservation of Free text plus incoming/local media. Google Play purchase verification, six-month recovery and owner-admin grant mutation remain later work.

## Canonical local workspace

The active owner working copy is `F:\NearMeU`. After every promoted batch it must be synchronized to promoted `main`.

## Current gate

Batch 06 runtime and acceptance are complete. Final documentation PR merge and recovery-branch fast-forward complete the promotion; Batch 07 is next.
