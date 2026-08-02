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
| 07 | Six-month automatic Premium backup and restore | ACCEPTED | Promote after docs merge |
| 08 | Profile sharing and deep-link recovery | PLANNED NEXT | Starts after Batch 07 promotion/local sync |
| 09 | Agora audio calling | PLANNED | Later |
| 10 | Agora video calling | PLANNED | Later |
| 11 | Owner-only Premium administration | PLANNED | Later |
| 12 | Full regression and Play Store readiness | PLANNED | Release-readiness gate |

## Batch 07 acceptance record

```text
Batch ID: 07
Title: Six-month Premium backup and restore
Status: ACCEPTED
Base: 87cdded675716a761372d0b7064d13ec3a8e40f8
Tested runtime commit: 5ae058122d927c7e35257fb80ca5fa879f14b784
Pull request: #98
Merged main runtime commit: db48338e6528b61e1e486d6d158c9d62e641c977
Version: 1.0.10+11
Android package: com.nearmeu.nearmeu
Build #79 / run 30746260270: PASS
Quality #480 / run 30746260318: PASS
Recoverable artifact ID: 8833110504
Recoverable artifact digest: sha256:75892030fb34647b64b89fd6f1ac3a94b48acac6bf24217eb63b69a5feb5c6fc
Physically tested signed debug APK SHA-256: 2af784329a1594a761877110c671508b19f8cd1cc2542d9079cc46a7b80025d1
Signed release artifact ID: 8833182373
Signed release artifact digest: sha256:4bc19b26851ab9349a578fb9fe64b6d609af16e0ff9da2432194a25106e4b403
Signed release APK SHA-256: 19a100dcfa64dc00bb71e918452d8c70d902d2b42ced8e72e6ef04eef5568442
Direct update continuity: PASS
Premium text restore: PASS
Premium sent photo restore: PASS
Clear Chat non-resurrection: PASS
Delete for Me non-resurrection: PASS
Delete for Everyone / Unsend non-resurrection: PASS
Cross-account Clear Chat isolation: PASS
Seven-day delivery-cloud regression: PASS
Free Premium recovery authorization: BACKEND-ENFORCED PASS
Receiver media pre/post-download recovery: OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS
Owner decision: ACCEPTED on 2026-08-02
```

Accepted Batch 07 scope includes separate per-user Premium recovery, six-calendar-month recorded retention, idempotent encrypted-local restore, Clear Chat cutoff enforcement, Delete-for-Me cleanup, Unsend/Delete-for-Everyone cleanup, recovery-media isolation, Auth-delete cleanup/retry handling and trusted Premium authorization for restore access.

## Canonical local workspace

The active owner working copy is `F:\NearMeU`. After promotion it must be synchronized to promoted `main` before Batch 08 starts.

## Current gate

Batch 07 runtime acceptance is complete. Remaining closeout work is documentation PR merge, recovery-branch promotion and canonical local workspace sync. Batch 08 must not start before those complete.
