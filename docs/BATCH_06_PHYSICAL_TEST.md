# Batch 06 Physical Acceptance — Premium Entitlement Foundation

Status: **OWNER ACCEPTED — FINAL CI / MERGE PENDING**

Target version: `1.0.9+10`

Branch: `batch/06-premium-entitlement-foundation`

Base: `3b749c8d7a320b71446245f99c694fdf85d9ccc4`

This was a focused test. The owner did **not** repeat the full Batch 01–05 matrices.

## Frozen behavior accepted

- One private Premium plan; no public Premium badge.
- Trusted server entitlement is the source of truth.
- Missing/expired entitlement is Free.
- Free keeps text messaging and incoming media playback.
- Free cannot initiate photo/video/voice-message sends.
- Locked outbound media/voice controls remain visible and clearly show a Premium requirement.
- Server `sendPrivateMediaMessage` independently enforces Premium so a modified client/local flag cannot unlock outbound private media.
- Google Play purchase verification is **not** implemented in this foundation batch.
- Six-month Premium backup/restore remains Batch 07.
- Owner-admin entitlement mutation remains Batch 11.

## Automated evidence

- Tested runtime commit: `52fe6a52ad117e9eccb922e535b9d6752af7e695`
- Build recoverable base #40 / run `30706204824`: PASS
- Quality gate #439 / run `30706204828`: PASS
- Recoverable artifact ID: `8820525497`
- Recoverable artifact digest: `sha256:7a6023c00bc328438efa4135f411286ae98c39485ff2c35f4385697eb78ea4e7`
- Signed debug APK SHA-256: `2df1a743c313ec8b90b73d52677e2de2360b02c3858e1f9dbd1735c1534a016f`
- Signed release artifact ID: `8820623151`
- Signed release artifact digest: `sha256:0998f97e18470ba2602c5dd84ae173c560f31b86c55f832e1af43200e63af65c`
- Signed release APK SHA-256: `4aac231c92283884cc8af1a5d88ad517c29ae716c7e541d9aa6a8be85d9f4b72`
- Android package: `com.nearmeu.nearmeu`
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Production deployment

The owner deployed the Batch 06 branch callables to Firebase project `nearmeu-e82c7`:

- `getMyPremiumEntitlement(asia-south1)`
- `sendPrivateMediaMessage(asia-south1)`

Initial post-deploy testing proved the callable existed because the prior `NOT_FOUND` changed to `UNAUTHENTICATED`. A client hardening patch then added one forced Firebase ID-token refresh and one retry for the entitlement read. The owner installed the new signed update artifact and verified the expected Premium-required responses on-device.

No production entitlement-grant callable was added in Batch 06.

## Focused owner acceptance

Owner evidence on 2026-08-01 confirmed:

1. Existing chat history and prior media remained present after direct update.
2. Normal Free text messaging remained usable.
3. Mic control showed its lock and, when tapped, displayed `Premium is required to send voice messages.` without starting recording.
4. Photo/video attachment control showed its lock and, when tapped, displayed `Premium is required to send photos or videos.` without opening the picker.
5. Previously received/local video and image content remained visible.
6. The owner explicitly reported: `Yes it's working`.

The earlier `UNAUTHENTICATED` result was not accepted as final behavior; it was fixed in runtime commit `52fe6a52ad117e9eccb922e535b9d6752af7e695` and the corrected behavior was physically retested.

## Premium-positive-path evidence

Because Google Play purchase verification and owner-admin grant controls are not introduced in Batch 06, production does not add a user-facing way to mint a Premium entitlement. The positive entitlement path is covered by automated policy tests against active `googlePlay` and `admin` grants. Physical acceptance therefore focused on the safe default-Free behavior, trusted callable availability and direct-update regression.

## Acceptance record

```text
Tested runtime commit: 52fe6a52ad117e9eccb922e535b9d6752af7e695
Build #40 / run 30706204824: PASS
Quality #439 / run 30706204828: PASS
Recoverable artifact ID/digest: 8820525497 / sha256:7a6023c00bc328438efa4135f411286ae98c39485ff2c35f4385697eb78ea4e7
Debug APK SHA-256: 2df1a743c313ec8b90b73d52677e2de2360b02c3858e1f9dbd1735c1534a016f
Release artifact ID/digest: 8820623151 / sha256:0998f97e18470ba2602c5dd84ae173c560f31b86c55f832e1af43200e63af65c
Release APK SHA-256: 4aac231c92283884cc8af1a5d88ad517c29ae716c7e541d9aa6a8be85d9f4b72
Permanent signing certificate: unchanged / verified
Production getMyPremiumEntitlement deployment: PASS
Production sendPrivateMediaMessage update: PASS
Direct-update preservation: PASS
Free text send: PASS
Free attachment lock: PASS
Free voice lock: PASS
Incoming/local media unchanged: PASS
No public Premium badge: scope preserved; no public badge introduced
Owner decision: ACCEPTED on 2026-08-01
```
