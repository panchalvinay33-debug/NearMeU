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
| 04 | Clear Chat and deletion semantics | ACCEPTED | Superseded by Batch 05 |
| 05 | Identity, account close and reactivation | ACCEPTED | Promoted official base |
| 06 | Premium entitlement foundation | ACCEPTED | Final CI / merge / promotion pending |
| 07 | Six-month automatic Premium backup and restore | PLANNED | After Batch 06 promotion |
| 08 | Profile sharing and deep-link recovery | PLANNED | Later |
| 09 | Agora audio calling | PLANNED | Later |
| 10 | Agora video calling | PLANNED | Later |
| 11 | Owner-only Premium administration | PLANNED | Later |
| 12 | Full regression and Play Store readiness | PLANNED | Release-readiness gate |

## Batch 01

- PR `#86`; merged runtime `9b4b5a03464240c5bfba449a2a0b8ceda1712c1f`; version `1.0.4+5`; owner accepted tick truth.

## Batch 02

- PR `#88`; merged runtime `d7a8c800d48beb7f646fb4d76d0afd7fbfeafa56`; version `1.0.5+6`; owner accepted photo/video/voice reliability.

## Batch 03

- PR `#90`; merged runtime `e98bd0ebe86dad1f689723a9e96f35095a015a7b`; final recovery docs `f487be76f958c06966e15f3db9cbbec65f5cfa9c`; version `1.0.6+7`; owner accepted.

## Batch 04

- PR `#92`; tested runtime `f22b36690b7ca65828ce2db809a89abe9931f83e`; merged runtime `d387b5cf8db7d9e792673ada4dd1c1d2958c7aee`; final recovery docs `c0a734e3dfbbab61b5c1b008df4e3f09bb011556`; version `1.0.7+8`; owner accepted Clear Chat/deletion semantics.

## Batch 05 acceptance record

```text
Batch ID: 05
Title: Identity, account close and reactivation
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
Status: ACCEPTED — merge/promotion pending
Branch: batch/06-premium-entitlement-foundation
Base: 3b749c8d7a320b71446245f99c694fdf85d9ccc4
Tested runtime commit: 52fe6a52ad117e9eccb922e535b9d6752af7e695
Pull request: #96
Version: 1.0.9+10
Android package: com.nearmeu.nearmeu
Build #40 / run 30706204824: PASS
Quality #439 / run 30706204828: PASS
Recoverable artifact ID: 8820525497
Recoverable artifact digest: sha256:7a6023c00bc328438efa4135f411286ae98c39485ff2c35f4385697eb78ea4e7
Tested signed debug APK SHA-256: 2df1a743c313ec8b90b73d52677e2de2360b02c3858e1f9dbd1735c1534a016f
Signed release artifact ID: 8820623151
Signed release artifact digest: sha256:0998f97e18470ba2602c5dd84ae173c560f31b86c55f832e1af43200e63af65c
Signed release APK SHA-256: 4aac231c92283884cc8af1a5d88ad517c29ae716c7e541d9aa6a8be85d9f4b72
Permanent signing certificate SHA-256: B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B
Production getMyPremiumEntitlement deployment: PASS
Production sendPrivateMediaMessage update: PASS
Direct-update/history/media preservation: PASS
Free text messaging: PASS
Free outbound voice lock: PASS
Free outbound photo/video lock: PASS
Prior received/local media remains accessible: PASS
Owner decision: ACCEPTED on 2026-08-01
```

Accepted scope:

- server evaluates effective Premium from independent Google Play/admin grant slots;
- missing/expired entitlement is Free;
- client reads effective entitlement only through a trusted callable;
- Free text remains available;
- outbound photo/video/voice controls remain visible with Premium locks;
- locked taps refresh server truth before allowing the original action;
- one forced Firebase ID-token refresh/retry hardens stale-token recovery;
- server independently refuses outbound image/video/voice creation without active Premium;
- current Premium status remains private from other users;
- Google Play purchase verification, six-month recovery, and owner-admin grant controls are not falsely claimed as implemented in Batch 06.

Focused physical matrix: [`BATCH_06_PHYSICAL_TEST.md`](BATCH_06_PHYSICAL_TEST.md).

## Canonical local workspace

The active owner working copy is `F:\NearMeU`. After every promoted batch it must be synchronized to promoted `main`. Downloads clones and `F:\NearMeU-OLD` are archives/backups, not the active project.

## Current gate

Batch 06 is physically owner-accepted. Only acceptance-head CI, PR #96 merge, final recovery documentation and `stable/official-recoverable-base` promotion remain before Batch 07 runtime work starts.
