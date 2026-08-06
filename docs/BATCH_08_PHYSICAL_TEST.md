# Batch 08 Physical Acceptance and Re-Certification

Original status: **ACCEPTED** on 2026-08-02

Fresh re-certification status: **FINAL CLOSEOUT IN PROGRESS** on 2026-08-06

Target version: `1.0.11+12`

## Original Base08 accepted scope

- Free and Premium users can share their own profile.
- Sharing is explicit opt-in.
- Shared links use opaque revocable public identifiers.
- Public web preview is generic and privacy-safe.
- Signed-in active users resolve the identifier through trusted backend logic.
- Bidirectional block relationships prevent shared-link bypass.
- Suspended/closed/missing/deleted profiles do not resolve.
- Sharing can be disabled/re-enabled and reset/rotated.
- HTTPS installed-app handling supports warm and cold start navigation.
- Auth deletion removes profile-sharing mappings.
- Existing chat, Premium, recovery and deletion semantics remain in scope.
- No post-Base08 calling/Admin experiment is part of this accepted runtime.

## Original automated evidence — 2026-08-02

- Tested runtime commit: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Merged runtime commit: `f83a6e92457f728f177dc062dcc9171c141a9217`
- PR: `#100`
- Build #90 / run `30750777554`: PASS
- Quality #493 / run `30750777555`: PASS
- Recoverable artifact ID: `8834500159`
- Recoverable artifact digest: `sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49`
- Physically tested signed debug APK SHA-256: `4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412`
- Signed release artifact ID: `8834548293`
- Signed release artifact digest: `sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a`
- Signed release APK SHA-256: `ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde`
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Original physical/backend acceptance matrix

- Direct update with `adb install -r` — PASS.
- Settings → Share My Profile loads — PASS.
- Explicit Sharing ON generates opaque HTTPS link — PASS.
- Android share flow — PASS.
- Public URL exposes no readable UID/email/phone/exact location — PASS.
- Generic privacy-safe web preview — PASS.
- HTTPS warm-start deep link — PASS.
- HTTPS cold-start deep link — PASS after same-batch navigation-race fix.
- Sharing OFF revokes current link — PASS.
- Re-enable restores current link — PASS.
- Reset while ON rotates link and invalidates old link — PASS.
- Reset while OFF preserves disabled state — owner-reported PASS.
- Bidirectional block bypass prevention — owner-reported PASS plus backend enforcement.
- Unblock restores normal resolution — owner-reported PASS.
- Suspended/missing/unshareable rejection — backend-enforced PASS.
- Auth-delete mapping cleanup — backend-trigger/automated PASS.
- Nearby/Chats/text/media regression smoke — owner-reported PASS.

## Fresh Base08 re-certification — 2026-08-06

The owner requested all post-Base08 work be frozen/cleaned and Base08 be physically re-certified before any future work.

Fresh physical testing found real stabilization defects that were corrected without introducing future-feature scope.

### Firestore chat index correction

Symptom: Chats/messages could fail with a failed-precondition for normal collection ordering on `messages.timestamp`.

Correction: restore Firestore automatic single-field collection indexes for `messages.timestamp` and remove the stale custom override from accepted source.

Fresh result: Chats physically loaded — PASS.

### Delivery receipt correction

Symptom: read state could become blue double tick while the intermediate delivered grey double tick failed.

Cause: client could acknowledge up to 200 message IDs but backend accepted at most 100, allowing backlog rejection.

Correction: backend delivery acknowledgement limit aligned to 200.

Fresh two-phone result:

- sender sends — single tick;
- receiver device receives without read — grey double tick;
- receiver reads — blue double tick;
- repeat reverse direction — PASS.

### Online presence correction

Symptom: both devices were active but did not reliably show each other Online.

Cause: chat last-seen writes could store `isOnline:false` while PresenceService cached its previous published `true` and skipped a corrective write.

Correction: PresenceService compares stored profile state with desired lifecycle state and forces correction when they differ.

Fresh two-phone mutual Online result — PASS.

### Fresh regression matrix

Owner-reported fresh PASS:

- install/session continuity;
- Nearby;
- Chats;
- text messaging;
- photo/video/voice messaging;
- message actions including unsend/delete-for-me/clear and restart behavior;
- block/safety;
- Premium gating / owner Premium flow;
- Profile Sharing regression;
- restart/network smoke;
- second-device App Check setup;
- mutual Online presence;
- grey delivered double tick;
- blue read double tick;
- bidirectional two-device messaging.

## Fresh automated evidence before About-only correction

- PR #112 merged on 2026-08-06.
- Merge SHA: `b6837ce2dd90bdc4db87a153089fcaf1cf74a441`.
- Quality #612 / run `31077990662`: PASS.
- Recoverable #166 / run `31077990677`: PASS.
- Recoverable artifact ID: `8958542675`.
- Recoverable artifact digest: `sha256:a44c7a8d9f4f4098e0bde90c48d165b8a3198a173c67f63bb81a6b92e425aa9f`.

## About-screen version correction candidate

A final audit found the About screen still hardcoded `Version 1.0.0` even though package version is `1.0.11+12`.

PR #114 changes only the About version display to runtime `PackageInfo`.

Automated candidate evidence:

- Branch head: `f0906b3be18e633102db07a6d74e837717d8cc60`
- Tested PR merge ref: `04c0050ac13a9930996a59c351fea98c3971bbfb`
- Quality #614 / run `31081417470`: PASS
- Recoverable #167 / run `31081418948`: PASS
- Recoverable artifact ID: `8959924645`
- Recoverable artifact digest: `sha256:e9fa15ed8056fd44210b6f89917627236cfaa44d430209766351e63aab9bb27d`
- Signed debug APK SHA-256: `532e1b521f0fc92b63da8e4e68188e2788f2fda5996a8f753191b1594246c069`
- Permanent signing certificate: PASS
- Focused physical expected label: `Version 1.0.11 (Build 12)`
- Focused physical result: **PENDING**

Do not mark this candidate final until the owner confirms the About label, PR114 is merged, production Firebase exact-base audit passes, authoritative docs/manifest are finalized and recovery promotion completes.

## Persistent evidence notes

- Batch07 receiver-media pre-download/post-download Premium recovery remains **OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS**.
- Batch08 custom `nearmeu://profile/...` fallback is implemented but was not separately captured as independent screenshot evidence. HTTPS warm/cold handling was physically verified.

## Current final gate

Machine-readable current gate: `config/official_base_manifest.json`.

Base08 becomes **STABLE RE-CERTIFIED / LOCKED** only after:

1. About version focused physical PASS;
2. PR114 merge;
3. production Firebase audit/drift cleanup;
4. docs/manifest finalization;
5. recovery branch promotion;
6. `F:\NearMeU` synchronization;
7. temporary branch cleanup/neutralization.
