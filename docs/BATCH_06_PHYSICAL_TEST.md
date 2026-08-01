# Batch 06 Physical Acceptance — Premium Entitlement Foundation

Status: **PENDING CI / PRODUCTION DEPLOYMENT / OWNER TEST**

Target version: `1.0.9+10`

Branch: `batch/06-premium-entitlement-foundation`

Base: `3b749c8d7a320b71446245f99c694fdf85d9ccc4`

This is a focused test. Do **not** repeat the full Batch 01–05 matrices unless a regression is observed.

## Frozen behavior under test

- One private Premium plan; no public Premium badge.
- Trusted server entitlement is the source of truth.
- Missing/expired entitlement is Free.
- Free keeps text messaging and incoming media playback.
- Free cannot initiate photo/video/voice-message sends.
- Locked outbound media/voice controls remain visible and clearly show a Premium requirement.
- Server `sendPrivateMediaMessage` independently enforces Premium so a modified client/local flag cannot unlock outbound private media.
- Google Play purchase verification is **not** implemented in this foundation batch.
- Six-month Premium backup/restore is Batch 07.
- Owner-admin entitlement mutation is Batch 11.

## Required automated gates

- Cloud Functions tests PASS, including entitlement expiry/source policy.
- Flutter formatter/analyze/tests PASS.
- Firebase Rules tests PASS.
- permanently signed debug/recovery APK PASS.
- permanently signed release APK PASS.
- package remains `com.nearmeu.nearmeu`.
- permanent signing certificate remains unchanged.

## Production deployment before physical test

Deploy:

- `getMyPremiumEntitlement(asia-south1)` — new trusted read callable;
- `sendPrivateMediaMessage(asia-south1)` — updated to enforce Premium.

No production entitlement-grant callable is added in Batch 06.

## Focused owner matrix

1. **Direct update smoke**
   - install with `adb install -r`; no uninstall/data wipe;
   - existing login, chats and app state remain available.

2. **Free text remains usable**
   - send one normal text message from a Free account;
   - receiver gets it normally.

3. **Free outbound Premium controls are visibly locked**
   - mic and photo/video attachment controls remain visible;
   - lock indicator is visible;
   - tapping mic shows that Premium is required and does not start microphone recording;
   - tapping attachment shows that Premium is required and does not open gallery/camera.

4. **Free incoming media remains usable**
   - previously downloaded/local photo/video/voice remains viewable/playable;
   - this batch must not hide or delete existing received media.

5. **No public Premium badge**
   - chat/profile/Nearby does not expose another user's Premium status.

## Premium-positive-path evidence in this batch

Because Google Play purchase verification and owner-admin grant controls are not introduced in Batch 06, production does not add a user-facing way to mint a Premium entitlement. The positive entitlement path is therefore covered by automated policy tests against active `googlePlay` and `admin` grants, while the physical device test focuses on the safe default-Free behavior and direct-update regression.

## Acceptance record

```text
Tested runtime commit: PENDING
Build workflow: PENDING
Quality workflow: PENDING
Recoverable artifact ID/digest: PENDING
Debug APK SHA-256: PENDING
Release artifact ID/digest: PENDING
Release APK SHA-256: PENDING
Permanent signing certificate: PENDING
Production getMyPremiumEntitlement deployment: PENDING
Production sendPrivateMediaMessage update: PENDING
Direct-update preservation: PENDING
Free text send: PENDING
Free attachment lock: PENDING
Free voice lock: PENDING
Incoming/local media unchanged: PENDING
No public Premium badge: PENDING
Owner decision: PENDING
```
