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

Example currently in this branch:

`1.0.11+12`

Meaning:
- user-facing version name: `1.0.11`;
- Android build/version code: `12`.

The build number must increase for every APK intended to supersede an earlier installable build. Do not distribute two materially different binaries with the same version/build identity.

## 3. Version must be identifiable before installation

The APK/ZIP filename must include the app version, build number, architecture and build type so the owner can identify the file before installing it.

Required filename pattern:

`NearMeU-v<version>-b<build>-<architecture>-<type>.apk`

Examples:
- `NearMeU-v1.0.11-b12-universal-release.apk`
- `NearMeU-v1.0.11-b12-arm64-release.apk`

ZIP artifacts should follow the same convention:

`NearMeU-v1.0.11-b12-arm64-release.zip`

GitHub Actions artifact names should also include the same version/build/architecture identity instead of relying only on a commit SHA.

The APK itself must retain matching Android `versionName` and `versionCode` metadata so package managers can inspect the same identity.

## 4. Version must be visible after installation

NearMeU must show its installed version inside the app, using runtime package metadata rather than a manually duplicated hard-coded string.

Required display location:
- Settings / About (or an equivalent stable owner-visible screen).

Required minimum display:
- `NearMeU version 1.0.11`
- `Build 12`

Recommended diagnostic display:
- build architecture/channel when useful;
- short source checkpoint/commit identifier for internal test builds.

`package_info_plus` should be used to read the installed package version/build at runtime so the displayed value always matches the APK metadata.

The version should also remain available through the operating system's application/package information where the Android device exposes it, but NearMeU must not rely only on OEM Settings UI because different Android vendors display package version information differently.

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

## 7. Batch 09 R2 application

For Batch 09 R2, all future test APK handoffs must follow this policy. The currently accepted CI checkpoint remains traceable by commit and artifact digest, but the next owner-distributed APK should use the new human-readable versioned filename convention and the in-app version display requirement must be completed before final Batch 09 R2 acceptance.
