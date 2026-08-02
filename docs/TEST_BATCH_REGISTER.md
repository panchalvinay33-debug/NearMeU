# NearMeU Test Batch Register

Last updated: 2026-08-02

Physical acceptance requires a signed artifact, checksum, device evidence and owner decision. Deferred evidence must remain explicitly marked as deferred and must never be rewritten as PASS.

## Batch table

| Batch | Title | Status | Recovery-base status |
|---|---|---|---|
| 00 | Governance, roadmap and decision freeze | ACCEPTED | Documentation foundation |
| 01 | Chat reliability and message-state truth | ACCEPTED | Superseded |
| 02 | Photo/video/voice-message reliability | ACCEPTED | Superseded |
| 03 | Local-first persistence and seven-day delivery cloud | ACCEPTED | Superseded |
| 04 | Clear Chat and deletion semantics | ACCEPTED | Superseded |
| 05 | Identity, account close and reactivation | ACCEPTED | Superseded |
| 06 | Premium entitlement foundation | ACCEPTED | Superseded by Batch 07 |
| 07 | Six-month automatic Premium backup and restore | ACCEPTED | Superseded by Batch 08 recovery base after promotion |
| 08 | Profile sharing and deep-link recovery | ACCEPTED | Promote after docs merge |
| 09 | Agora audio calling | PLANNED NEXT | Starts after Batch 08 promotion/local sync |
| 10 | Agora video calling | PLANNED | Later |
| 11 | Owner-only Premium administration | PLANNED | Later |
| 12 | Full regression and Play Store readiness | PLANNED | Release-readiness gate |

## Batch 08 acceptance record

```text
Batch ID: 08
Title: Profile sharing and deep-link recovery
Status: ACCEPTED
Base: ff551ceb48d3fc1d957141977df29ebb31837b87
Tested runtime commit: fdc9b22322a96b793fff3058b1ca990f656e80a1
Pull request: #100
Merged main runtime commit: f83a6e92457f728f177dc062dcc9171c141a9217
Version: 1.0.11+12
Android package: com.nearmeu.nearmeu
Build #90 / run 30750777554: PASS
Quality #493 / run 30750777555: PASS
Recoverable artifact ID: 8834500159
Recoverable artifact digest: sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49
Physically tested signed debug APK SHA-256: 4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412
Signed release artifact ID: 8834548293
Signed release artifact digest: sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a
Signed release APK SHA-256: ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde
Profile Sharing initial load: PASS
Opaque HTTPS share link: PASS
Android share flow: PASS
Generic web preview: PASS
HTTPS warm-start deep link: PASS
HTTPS cold-start deep link: PASS after same-batch fix
Sharing OFF revocation: PASS
Re-enable current link: PASS
Reset / old-link invalidation / new-link resolution: PASS
Reset while OFF preserves disabled state: OWNER-REPORTED PASS
Bidirectional block-bypass prevention: OWNER-REPORTED + BACKEND-ENFORCED PASS
Suspended/missing/unshareable profile rejection: BACKEND-ENFORCED PASS
Auth-delete share mapping cleanup: AUTOMATED/BACKEND PASS
Regression smoke: OWNER-REPORTED PASS
Custom nearmeu:// fallback: IMPLEMENTED / NOT SEPARATELY SCREENSHOT-VERIFIED
Owner decision: ACCEPTED on 2026-08-02
```

## Persistent evidence note from Batch 07

Receiver-media pre-download/post-download Premium recovery eligibility remains **OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS**. Batch 08 does not change or erase that evidence gap.

## Canonical local workspace

The active owner working copy is `F:\NearMeU`. After Batch 08 closeout promotion it must be synchronized to promoted `main` before Batch 09 starts.

## Current gate

Batch 08 runtime acceptance and merge are complete. Remaining closeout work is final documentation merge, recovery-branch promotion and canonical local workspace sync. Batch 09 must not start before those complete.
