# NearMeU production release runbook

This runbook covers the controlled path from a green `main` branch to a Google Play internal-test App Bundle. Never build or upload a production artifact from an unreviewed feature branch.

## 1. One-time GitHub setup

Create a protected GitHub Environment named `production-release`. Add required reviewers so a signed build cannot start without manual approval.

Add these environment secrets:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`: base64-encoded private upload keystore bytes.
- `ANDROID_KEYSTORE_PASSWORD`: upload keystore password.
- `ANDROID_KEY_PASSWORD`: private key password.
- `ANDROID_KEY_ALIAS`: upload key alias.

Keep the original keystore and passwords in a separate secure backup. Losing the upload key can delay or block future updates. Never commit a real `.jks`, `.keystore`, or `key.properties` file.

Example local encoding command:

```bash
base64 -w 0 upload-keystore.jks
```

Paste the output directly into the GitHub environment secret. Do not paste it into issues, pull requests, chat, or logs.

## 2. Versioning rule

The single release version source is `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- `1.0.0` becomes Android `versionName`.
- `1` becomes Android `versionCode`.
- Every Play upload must use a versionCode greater than every previously uploaded build.
- Increase the version before triggering a new production AAB, including rejection fixes and internal-test replacements.

The Android Gradle configuration reads both values from Flutter. Do not hardcode them in `android/app/build.gradle.kts`.

## 3. Required green gates

Before building a signed artifact, confirm the latest `main` quality run passed:

- Dart formatter and Flutter analyze.
- Flutter unit/widget tests.
- Debug APK build.
- Firestore emulator security tests.
- Cloud Functions tests and secure module loading.
- Unsigned release-build refusal.

Also confirm all intended release pull requests are merged and no emergency security fix remains open.

## 4. Firebase production preparation

Before enabling a Play internal test:

1. Deploy current Firestore rules and indexes.
2. Deploy Cloud Functions from the secure `functions/bootstrap.js` entrypoint.
3. Register the Play signing and upload certificate SHA-256 fingerprints in Firebase.
4. Confirm Google Sign-In works with the Play-distributed certificate.
5. Register and validate Firebase App Check Play Integrity for `com.nearmeu.nearmeu`.
6. Confirm FCM, Crashlytics, Analytics, and Performance dashboards are connected to the same production Firebase project.
7. Keep enforcement rollout controlled so old clients are not unexpectedly locked out before the new build is installed.

## 5. Build the signed AAB

From GitHub Actions:

1. Open **Build signed production AAB**.
2. Select **Run workflow** on the `main` branch.
3. Approve the `production-release` environment review.
4. Confirm the workflow validates the version, decodes the private keystore, verifies the alias, builds an obfuscated release AAB, verifies the bundle signature, and removes signing files.

Download and retain both workflow artifacts:

- Signed AAB, SHA-256 checksum, and release metadata.
- Dart obfuscation symbols for that exact version and commit.

Verify the downloaded AAB checksum before upload:

```bash
sha256sum -c app-release.aab.sha256
```

## 6. Google Play internal testing

Upload the AAB to the internal-testing track first. Complete or verify:

- App name, icon, feature graphic, phone screenshots, short description, and full description.
- Privacy policy URL.
- Data safety declarations for location, account/profile data, messages, diagnostics, analytics, app performance, and fraud/security use.
- App access instructions if review requires an authenticated flow.
- Content rating questionnaire.
- Target audience and age declarations.
- Ads declaration.
- Account deletion disclosure and working in-app deletion path.
- Contact details and release notes.

Do not promote directly to production after the first successful upload.

## 7. Real-device acceptance test

Install only from Google Play internal testing and test on at least two physical Android devices and two accounts:

- Fresh install and Google Sign-In.
- Profile completion and permissions denied/allowed paths.
- Nearby discovery at supported radius limits.
- Two-way private chat, reply, seen, unsend, delete-for-me, and push notification opening.
- Message and report rate-limit behavior.
- Block/unblock, suspension handling, logout, and account deletion.
- Background/foreground presence and token unregister behavior.
- Play Integrity App Check, Crashlytics non-fatals, Analytics navigation, and Performance startup trace.
- No email, raw UID, exact coordinates, token, profile name, or message text in telemetry dashboards.

Record the tested AAB SHA-256, version, devices, Android versions, Firebase project, test accounts, and result.

## 8. Promotion decision

Promote to closed testing only when there are no launch-blocking crashes, authentication failures, message delivery failures, privacy leaks, or App Check rejection loops. Promote to production gradually and watch Crashlytics, ANRs, login success, notification delivery, and account deletion during rollout.

If Google Play rejects a release, fix the stated issue, increment the versionCode, build a new signed AAB through the same workflow, and submit again. Keep every uploaded artifact and its symbol set traceable to its Git commit.
