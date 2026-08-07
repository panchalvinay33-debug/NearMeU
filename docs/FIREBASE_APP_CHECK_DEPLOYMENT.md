# Firebase App Check deployment

NearMeU activates Firebase App Check before any client backend service starts.

## Providers

- Android debug/development builds use the Firebase App Check debug provider.
- Normal Android release builds use Google Play Integrity.
- PR physical-test release builds may explicitly set `NEARMEU_APP_CHECK_DEBUG=true`; these remain permanently signed but use the App Check debug provider only for controlled sideloaded physical testing.
- Callable Cloud Functions are loaded through `functions/bootstrap.js`, which enables global App Check enforcement before exporting function definitions.

The debug override is opt-in and defaults to `false`. A normal release build without the explicit Dart define always uses Play Integrity.

## Firebase Console steps before production enforcement

1. Register the Android app `com.nearmeu.nearmeu` with Firebase App Check.
2. Select **Play Integrity** as the Android provider.
3. Add the upload/app-signing SHA-256 fingerprints used by the Play release.
4. For local or sideloaded physical testing, install a debug-provider build, copy its App Check debug token from device logs, and register that token in the Firebase Console. Each physical device may have a different debug token.
5. Deploy Cloud Functions from the consumer repository only after the applicable deployment gate passes.
6. Confirm callable requests succeed from a registered debug-provider physical-test build and later from a Play-distributed release build.
7. In the Firebase Console, enable App Check enforcement for Firestore and Storage only after the registered clients have been verified.

## Physical-test artifact rule

CI produces two distinct signed release artifacts when permanent signing is available on a pull request:

- `nearmeu-signed-release-apk-<sha>`: production-mode App Check using Play Integrity.
- `nearmeu-signed-physical-test-apk-<sha>`: controlled physical-test build using the App Check debug provider.

The physical-test artifact must never be treated as a Play Store production artifact. It exists so sideloaded two-phone acceptance can exercise callable Cloud Functions while global App Check enforcement remains enabled.

## Safe rollout

Do not disable global callable App Check enforcement to make sideloaded testing pass. Register only the required current device debug tokens, remove obsolete tokens after testing, and keep normal release builds on Play Integrity.

Do not enable product-level enforcement before registering the production signing fingerprints and any required development debug tokens. Otherwise legitimate clients can be rejected until their App Check configuration is corrected.

## Verification

The quality gate verifies:

- Flutter dependency resolution and compilation with `firebase_app_check`.
- Debug APK construction.
- Permanently signed normal release construction when signing secrets are available.
- Permanently signed PR physical-test APK construction with the explicit debug App Check override.
- Cloud Functions tests.
- The Functions deploy entrypoint points to the App Check bootstrap.
- App Check enforcement is configured before function definitions are loaded.
