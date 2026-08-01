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
| 05 | Identity, account close and reactivation | ACCEPTED | Promoted official base after final docs merge |
| 06 | Premium entitlement foundation | PLANNED | Next batch |
| 07 | Six-month automatic Premium backup and restore | PLANNED | Later |
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
Branch: batch/05-identity-account-close-reactivation
Base: c0a734e3dfbbab61b5c1b008df4e3f09bb011556
Tested runtime commit: d2868b97dc931a49f625f4711db4b555fecd34ec
Physical acceptance evidence head: 311b8a364d9701c6424cad719c5a5aa50a7c0bf6
Pull request: #94
Merged main runtime commit: 44143f612cbf8b7adf6d591abe74aac2c6397704
Version: 1.0.8+9
Android package: com.nearmeu.nearmeu
Build #33 / run 30699307402: PASS
Quality #430 / run 30699307401: PASS
Acceptance-head Build #36 / run 30700741431: PASS
Acceptance-head Quality #433 / run 30700741441: PASS
Recoverable artifact ID: 8818404060
Recoverable artifact digest: sha256:70505abc00881695754c70684ae4140ab05224c1c424d242d6cdc9d11e20e94c
Tested signed debug APK SHA-256: c3371eb86c73a090b311c4d42656d8eaf799025aa04cd56da3bc6f51faeaf406
Signed release artifact ID: 8818505561
Signed release APK SHA-256: e648ece943692ae4d7bcc083088f8ecbdde91a5c1fb892344076bff0bf8c1966
Permanent signing certificate SHA-256: B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B
Direct-update/history preservation: PASS
Closed account neutral unavailable state: PASS
Closed-account message authorization refusal: PASS
Same-account reactivation/profile recreation: PASS
Conversation continuity after reactivation: PASS
Sign Out / Close Account / Permanent Delete separation: PASS
Owner decision: ACCEPTED on 2026-08-01
```

Detailed physical matrix: [`BATCH_05_PHYSICAL_TEST.md`](BATCH_05_PHYSICAL_TEST.md).

## Canonical local workspace

The active owner working copy is `F:\NearMeU`. After every promoted batch it must be synchronized to promoted `main`. Downloads clones and `F:\NearMeU-OLD` are archives/backups, not the active project.

## Current gate

Batch 05 runtime is merged and owner-accepted. Final acceptance docs must pass CI, merge, and then `stable/official-recoverable-base` must be fast-forwarded to that final docs merge. Batch 06 starts only from the promoted Batch 05 base.
