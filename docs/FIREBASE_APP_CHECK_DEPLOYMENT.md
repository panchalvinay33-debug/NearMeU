# Firebase App Check deployment

NearMeU activates Firebase App Check before any client backend service starts.

## Providers

- Android debug/development builds use the Firebase App Check debug provider.
- Android release builds use Google Play Integrity.
- Callable Cloud Functions are loaded through `functions/bootstrap.js`, which enables global App Check enforcement before exporting function definitions.

## Firebase Console steps before production enforcement

1. Register the Android app `com.nearmeu.nearmeu` with Firebase App Check.
2. Select **Play Integrity** as the Android provider.
3. Add the upload/app-signing SHA-256 fingerprints used by the Play release.
4. For local development, run a debug build, copy the App Check debug token from device logs, and register it in the Firebase Console.
5. Deploy Cloud Functions from the repository root with `firebase deploy --only functions`.
6. Confirm callable requests succeed from a registered debug build and a Play-distributed release build.
7. In the Firebase Console, enable App Check enforcement for Firestore and Storage only after the registered clients have been verified.

## Safe rollout

Do not enable product-level enforcement before registering the production signing fingerprints and any required development debug tokens. Otherwise legitimate clients can be rejected until their App Check configuration is corrected.

## Verification

The quality gate verifies:

- Flutter dependency resolution and compilation with `firebase_app_check`.
- Debug APK construction.
- Cloud Functions tests.
- The Functions deploy entrypoint points to the App Check bootstrap.
- App Check enforcement is configured before function definitions are loaded.
