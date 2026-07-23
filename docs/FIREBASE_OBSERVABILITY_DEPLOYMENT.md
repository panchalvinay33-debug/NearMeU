# Firebase observability rollout

NearMeU uses Firebase Crashlytics, Google Analytics for Firebase, and Firebase Performance Monitoring. Production release builds collect telemetry by default. Debug and profile builds keep collection disabled unless an internal tester explicitly opts in.

## Firebase Console preparation

1. Confirm the Android app `com.nearmeu.nearmeu` is registered in the production Firebase project.
2. Enable Google Analytics for the Firebase project and select the intended Analytics property.
3. Open Crashlytics and Performance Monitoring once in Firebase Console so their dashboards are initialized.
4. Keep the checked-in `google-services.json` aligned with the production Firebase project before making a signed release.

## Internal testing

Normal debug builds do not send Analytics, Crashlytics, or Performance data. To test the integration on a controlled device, run:

```bash
flutter run --dart-define=ENABLE_FIREBASE_OBSERVABILITY=true
```

Use Analytics DebugView for test events. A deliberate test crash should exist only in temporary internal code or a local test branch; never ship a user-facing crash button.

## Privacy rules

- Do not log email addresses, raw Firebase UIDs, FCM/App Check tokens, phone numbers, profile names, photos, exact coordinates, addresses, chat text, report descriptions, or media URLs.
- Analytics event parameters and Performance trace attributes must describe app state or operation categories only.
- Crashlytics custom keys must remain low-cardinality and non-identifying.
- Moderation and abuse telemetry must never contain private message content.

The application-side policy filters common sensitive parameter names. That filter is a final guard, not permission to pass sensitive data into telemetry calls.

## Release validation

Before production rollout:

1. Run the full GitHub Actions quality gate.
2. Build a signed Android App Bundle with the private upload keystore.
3. Install an internal-test build from Google Play so Play Integrity and release-only observability behavior are exercised together.
4. Trigger one harmless Analytics event and a controlled non-fatal exception.
5. Confirm the event appears in Analytics/DebugView and the non-fatal appears in Crashlytics.
6. Exercise login, nearby discovery, private chat, notification opening, report submission, logout, and account deletion while checking Performance traces and Crashlytics stability.
7. Verify no private content appears in Firebase dashboards.

## Obfuscation and symbols

When release builds use Dart obfuscation, preserve the generated symbol directory securely:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Do not commit symbol files to Git. Retain the exact symbols for every published version so Dart stack traces can be decoded later. The Crashlytics Gradle plugin handles native Android mapping uploads during a correctly configured release build.

## Play Console and legal disclosure

Update the Google Play Data safety form and the NearMeU privacy policy to accurately disclose Analytics, Crashlytics, and Performance Monitoring collection before publishing the build. Describe collection purposes such as app analytics, reliability, fraud prevention, diagnostics, and performance. Disclosures must match the actual Firebase configuration and current product behavior.

## Rollout order

1. Merge and deploy the observability-enabled client configuration.
2. Publish to internal testing first.
3. Observe Crashlytics stability, Analytics event quality, and Performance traces without expanding telemetry fields.
4. Fix launch-blocking crashes or slow startup/network paths.
5. Promote through closed testing and then production only after real-device validation is clean.
