# NearMeU Test Batch Register

Last updated: 2026-08-06

Physical acceptance requires a permanently signed artifact, traceable source/merge ref, checksum, device evidence and owner decision. Deferred evidence must remain explicitly deferred and must never be rewritten as PASS.

## Accepted product boundary

| Batch | Scope | Status |
|---|---|---|
| 00 | Governance, roadmap and controlled process | ACCEPTED |
| 01 | Chat reliability and message-state truth | ACCEPTED |
| 02 | Photo/video/voice-message reliability | ACCEPTED |
| 03 | Local-first persistence and seven-day temporary delivery cloud | ACCEPTED |
| 04 | Clear Chat and deletion semantics | ACCEPTED |
| 05 | Identity, account close and reactivation | ACCEPTED |
| 06 | Premium entitlement foundation | ACCEPTED |
| 07 | Six-month Premium backup and restore | ACCEPTED with persistent deferred receiver-media evidence |
| 08 | Profile sharing and deep-link recovery | ACCEPTED original scope; fresh re-certification closeout in progress |

There is no active accepted Batch09. Historical post-Base08 experiments are not part of the current product boundary.

## Original Batch08 acceptance record

```text
Accepted: 2026-08-02
Tested runtime: fdc9b22322a96b793fff3058b1ca990f656e80a1
Merged runtime: f83a6e92457f728f177dc062dcc9171c141a9217
PR: #100
Version: 1.0.11+12
Build #90 / run 30750777554: PASS
Quality #493 / run 30750777555: PASS
Recoverable artifact ID: 8834500159
Recoverable artifact digest: sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49
Physically tested signed debug APK SHA-256: 4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412
Signed release artifact ID: 8834548293
Signed release artifact digest: sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a
Signed release APK SHA-256: ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde
```

Original Base08 accepted profile-sharing evidence included explicit opt-in, opaque HTTPS link, Android share flow, generic web preview, HTTPS warm/cold deep links, sharing OFF/re-enable, reset/old-link invalidation, block-bypass prevention and regression smoke.

## Base08 fresh re-certification record — 2026-08-06

Fresh physical PASS reported by owner:

- login/session continuity;
- Nearby;
- Chats;
- text messaging;
- photo/video/voice messaging;
- message actions and restart persistence;
- block/safety;
- Premium gating / owner Premium flow;
- Profile Sharing regression;
- restart/network smoke;
- two-device mutual Online presence;
- single → grey double delivered → blue double read tick transition;
- bidirectional two-device messaging.

Stabilization defects found/fixed:

- Firestore automatic `messages.timestamp` collection index restored;
- delivery receipt client/backend batch limit aligned;
- stale online presence self-heal added;
- About-screen hardcoded version replaced by runtime package-version candidate.

Cleanup PR `#112` merged 2026-08-06 with merge SHA `b6837ce2dd90bdc4db87a153089fcaf1cf74a441`.

Fresh automated evidence before About-only correction:

```text
Quality #612 / run 31077990662: PASS
Recoverable #166 / run 31077990677: PASS
Recoverable artifact ID: 8958542675
Recoverable artifact digest: sha256:a44c7a8d9f4f4098e0bde90c48d165b8a3198a173c67f63bb81a6b92e425aa9f
```

About version-display candidate:

```text
PR: #114
Branch head: f0906b3be18e633102db07a6d74e837717d8cc60
Tested PR merge ref: 04c0050ac13a9930996a59c351fea98c3971bbfb
Quality #614 / run 31081417470: PASS
Recoverable #167 / run 31081418948: PASS
Recoverable artifact ID: 8959924645
Recoverable artifact digest: sha256:e9fa15ed8056fd44210b6f89917627236cfaa44d430209766351e63aab9bb27d
Signed debug APK SHA-256: 532e1b521f0fc92b63da8e4e68188e2788f2fda5996a8f753191b1594246c069
Focused physical About version display: PENDING
Expected label: Version 1.0.11 (Build 12)
```

Do not rewrite this candidate as final accepted until the focused physical check, merge, production audit, manifest/docs update and recovery promotion are complete.

## Persistent evidence notes

- Batch07 receiver-media pre-download/post-download Premium recovery remains **OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS**.
- Batch08 custom `nearmeu://` fallback is implemented but was not separately screenshot-verified; HTTPS warm/cold links were physically verified.

## Current closeout gate

The authoritative live gate is `config/official_base_manifest.json`.

Base08 final closeout requires:

1. About version physical PASS;
2. PR114 merge;
3. production Firebase exact-base audit and drift cleanup if needed;
4. authoritative docs/manifest finalization;
5. recovery-branch promotion;
6. `F:\NearMeU` synchronization;
7. temporary branch cleanup/neutralization.

Only after those complete is Base08 marked fully re-certified and locked.
