# NearMeU Build, Artifact Reuse and Version Identity Policy

Status: REQUIRED for all future NearMeU APKs and release candidates.

## 1. Core rule — do not rebuild a tested checkpoint unnecessarily

A successfully tested and accepted APK is a reusable artifact. If the app source, Android build configuration, dependencies, signing configuration and target architecture have not changed, do not rebuild the full Flutter/Gradle/Agora native stack only to obtain the same APK again.

Preferred order:

1. Reuse the already verified artifact from the accepted checkpoint.
2. Verify its recorded SHA-256 digest and signing identity before distribution.
3. Rebuild only when source/config/dependency/signing/ABI/version actually changes, or when the existing artifact has expired or is unavailable.
4. Architecture-specific APKs such as ARM64 are separate artifacts and require one build for that architecture, but once verified they should also be reused.
5. Never replace an accepted artifact silently with a newly rebuilt binary under the same visible version.

Every accepted checkpoint should record:
- Git commit SHA;
- app version name;
- Android version code/build number;
- architecture (`universal`, `arm64-v8a`, etc.);
- build type (`debug`, `release`);
- signing certificate fingerprint or trusted signing identity reference;
- artifact SHA-256 digest;
- CI run number;
- physical-test status where applicable.

## 2. Mandatory version identity

Every distributable NearMeU APK must have a unique, visible version identity.

Flutter source of truth remains `pubspec.yaml`:

`version: MAJOR.MINOR.PATCH+BUILD`

Current branch example:

`1.0.12+13`

Meaning:
- user-facing version name: `1.0.12`;
- Android build/version code: `13`.

The build number must increase for every APK intended to supersede an earlier installable build. Do not distribute two materially different binaries with the same version/build identity.

## 3. Version must be identifiable before installation

The APK/ZIP filename must include the app version, build number, architecture and build type so the owner can identify the file before installing it.

Required filename pattern:

`NearMeU-v<version>-b<build>-<architecture>-<type>.apk`

Examples:
- `NearMeU-v1.0.12-b13-universal-debug.apk`
- `NearMeU-v1.0.12-b13-arm64-release.apk`

ZIP artifacts should follow the same convention.

GitHub Actions artifact names should also include the same version/build/architecture identity instead of relying only on a commit SHA.

The APK itself must retain matching Android `versionName` and `versionCode` metadata so package managers can inspect the same identity.

## 4. Version must be visible after installation

NearMeU must show its installed version inside the app, using runtime package metadata rather than a manually duplicated hard-coded string.

Required display location:
- Settings > About NearMeU.

Required minimum display:
- `Version 1.0.12`
- `Build 13`

`package_info_plus` must be used to read the installed package version/build at runtime so the displayed value always matches the APK metadata.

The version should also remain available through the operating system's application/package information where Android exposes it, but NearMeU must not rely only on OEM Settings UI.

## 5. Release/test workflow

For every new test build:

1. Decide whether an existing accepted APK can be reused.
2. If reuse is valid, use the existing verified artifact and recorded digest.
3. If a new binary is necessary, bump the build number before distribution when it supersedes an earlier binary.
4. Build only the required architecture(s).
5. Verify signing and artifact digest.
6. Rename/package the artifact using the mandatory versioned filename.
7. Record CI + digest + commit + version in the relevant batch document/PR checkpoint.
8. During owner testing, always report the exact version/build being tested.

## 6. No ambiguous APKs

Do not hand the owner files with ambiguous names such as only:
- `app-release.apk`
- `app-debug.apk`
- `nearmeu.apk`

Those names may exist as temporary compiler outputs, but the user-facing/downloadable artifact must be renamed to the versioned NearMeU convention before handoff.

## 7. Firebase App Check and sideload physical testing

NearMeU callable backend functions enforce Firebase App Check globally. The Android app intentionally uses:
- `AndroidProvider.debug` for debug builds;
- `AndroidProvider.playIntegrity` for release builds.

Therefore physical-test APK selection is part of the acceptance process, not a cosmetic choice.

Rules:

1. Direct/sideload development testing outside Google Play should use the permanently signed **debug** APK with Firebase App Check debug-provider registration configured for the test device/build.
2. Do not interpret a sideloaded release APK that fails App Check / Play Integrity as a Nearby or Chats regression until App Check attestation has been verified.
3. Production/release acceptance must use the release APK with the intended Play Integrity/App Check production configuration.
4. Never disable backend App Check enforcement merely to make a test APK appear to work.
5. Nearby and Chats physical regression testing must distinguish actual connectivity failures from `unauthenticated`, `permission-denied`, App Check/attestation, backend-function, and Firestore-rule failures.
6. If a release APK is intentionally distributed outside Google Play, the Firebase App Check Play Integrity configuration must explicitly support that distribution model before it is considered a valid release-test channel.
7. Record which App Check provider/channel was used for every physical test checkpoint.

Observed Batch 09 R2 lesson: a sideloaded release build showed generic connection errors in both Nearby and Chats while both features shared protected Firebase callable/backend access. That result is classified as an infrastructure/App Check test-channel failure until attestation is verified, not as proof that the untouched Nearby/Chats UI code regressed.

## 8. Batch 09 R2 application

For Batch 09 R2, all future test APK handoffs must follow this policy. The current app version is `1.0.12+13`, with Settings > About reading the real installed version/build at runtime. Sideload physical regression testing should use the signed debug test channel first; final production acceptance still requires the signed release/Play Integrity path.
