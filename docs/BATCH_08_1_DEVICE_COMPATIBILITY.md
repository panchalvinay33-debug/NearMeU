# NearMeU Batch08.1 — Android Device Compatibility Hardening

Status: implementation branch only; **DO NOT MERGE until Base08 final lock/promotion is complete**.

## Goal

Keep NearMeU installable and usable across a broad range of supported Android phones without claiming universal compatibility. Batch08.1 must identify and remove accidental Play Store/device filters, verify representative Android API levels and CPU ABIs, and physically test common manufacturer behaviors before Batch09 calling work is accepted.

## Compatibility contract

- Android application id remains `com.nearmeu.nearmeu`.
- `compileSdk` / `targetSdk` remain current enough for Play policy.
- Effective `minSdk` must be measured from the built APK; it must not be raised without an explicit compatibility decision and evidence.
- Hardware used by optional features must not unnecessarily become a Play Store install requirement.
- Microphone/location-related hardware is treated as optional at install time; the app must handle permission/capability absence gracefully at runtime.
- Universal Android support is **not** claimed. Unsupported/untested devices must be recorded explicitly.

## Automated gates

1. Flutter analyze/tests and Android build must pass.
2. Build a universal debug APK and inspect its manifest with Android build tools.
3. Record package id, min SDK, target SDK, declared hardware features and native ABIs.
4. Fail if camera, telephony, Bluetooth, GPS or microphone hardware is accidentally marked required for installation.
5. Require ARM64 support for modern physical Android phones. Record any additional ABI coverage produced by the build.
6. Keep cleartext traffic disabled and preserve existing signing/application identity.

## Representative Android/API coverage

CI/build smoke coverage should include the oldest supported API resolved from the APK plus representative modern APIs. Physical acceptance should include, where reasonably available:

- Samsung
- Xiaomi / Redmi / Poco
- Vivo / iQOO
- Oppo / Realme
- Motorola
- Pixel / near-stock Android
- at least one lower-RAM / lower-end device

## Physical smoke matrix

For each representative device used, record:

- clean install or update install
- cold start / warm start
- sign in / session recovery
- Nearby with location denied, allowed and later revoked
- Chats list and chat open
- text send/receive
- photo/video/voice media path where hardware/permission is available
- notifications allowed/denied
- profile sharing / HTTPS app link
- offline cached Nearby/Chats and reconnect refresh
- background/resume behavior
- manufacturer battery/background restriction observations

## Batch boundary

Batch09 Audio Calling must not be accepted/merged before Batch08.1 is complete and owner-accepted. The existing Batch09 work branch must later be reconciled onto the accepted post-08.1 main.