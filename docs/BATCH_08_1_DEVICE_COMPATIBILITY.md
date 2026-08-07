# NearMeU Batch08.1 — Android Device Compatibility Hardening

Status: **coding implementation complete on the Batch08.1 branch; automated and physical verification pending**.

Base08 is now promoted and locked. Before Batch08.1 acceptance/merge, this implementation must be reconciled onto the final accepted Base08 main and all required CI/physical gates must pass.

## Goal

Keep NearMeU installable and usable across a broad range of supported Android phones without claiming universal compatibility. Batch08.1 identifies and removes accidental Play Store/device filters, verifies representative Android API levels and CPU ABIs, adds emulator/low-RAM smoke coverage, and defines repeatable physical OEM testing before Batch09 calling work is accepted.

## Compatibility contract

- Android application id remains `com.nearmeu.nearmeu`.
- `compileSdk` / `targetSdk` remain current enough for Play policy.
- Effective `minSdk` is measured from the built APK and must not silently rise above API 24 without an explicit compatibility decision and fresh evidence.
- Hardware used by optional features must not unnecessarily become a Play Store install requirement.
- Camera, microphone and location-related hardware are optional at install time; capability/permission absence must be handled gracefully at runtime.
- ARM64 support is required when the APK contains native payloads.
- Universal Android support is **not** claimed. Unsupported/untested devices remain explicitly unverified.

## Implemented automated gates

1. Flutter analyze/tests and Android build.
2. Universal debug APK build and Android `aapt` compatibility inspection.
3. Package id, effective min SDK, target SDK, declared hardware features and native ABI recording.
4. Fail if sensitive camera, telephony, Bluetooth, GPS, location or microphone hardware is accidentally marked required for installation.
5. Fail if effective `minSdk` rises above API 24 without deliberate review.
6. Require target SDK policy floor and ARM64 when native payload exists.
7. Emulator install/start/process/crash smoke tests on representative APIs 23, 29, 33 and 35.
8. Constrained Android API 29 emulator smoke with 1536 MB RAM.
9. Diagnostic artifact capture for launch output, activity state, process list and logcat.
10. Reusable connected-real-device PowerShell runner that records manufacturer/model/API/ABI/RAM, installs, launches and captures evidence.

## Repository implementation

- `.github/workflows/device-compatibility.yml`
- `tool/check_android_apk_compatibility.sh`
- `tool/android_emulator_smoke.sh`
- `tool/run_connected_android_compatibility.ps1`
- `docs/BATCH_08_1_PHYSICAL_DEVICE_MATRIX.md`
- Android manifest optional-hardware declarations for camera/microphone/location families

## Representative Android/API coverage

Automated smoke coverage targets API 23, 29, 33 and 35 plus a constrained-memory API 29 emulator. Physical acceptance should include, where reasonably available:

- Samsung
- Xiaomi / Redmi / Poco
- Vivo / iQOO
- Oppo / Realme
- Motorola
- Pixel / near-stock Android
- at least one lower-RAM / lower-end device

## Physical acceptance

Use `docs/BATCH_08_1_PHYSICAL_DEVICE_MATRIX.md` as the canonical matrix. It covers clean/update install, cold/warm start, authentication/session recovery, Nearby/location permission states, Chats/text/media, notifications, profile links, offline cache/reconnect, background/resume, process restart and OEM battery/background restrictions.

The connected-device helper validates install/start stability only; feature-level behavior still requires physical checks.

## Batch boundary

Batch08.1 is not PASS merely because coding is complete. Acceptance requires:

- reconciliation onto final promoted Base08 main;
- required CI green;
- clean APK compatibility report;
- emulator/low-RAM smoke PASS;
- representative physical device evidence;
- signed build availability;
- no unresolved major OEM-specific blocker;
- explicit owner acceptance.

Batch09 Audio Calling remains blocked from acceptance/merge until Batch08.1 is accepted. The existing Batch09 branch must later be reconciled onto accepted post-08.1 main.
