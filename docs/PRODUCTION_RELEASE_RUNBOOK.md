# NearMeU production release runbook

This runbook covers the controlled path from a green `main` branch to Firebase activation and a Google Play internal-test App Bundle. Never deploy Firebase resources or build a production artifact from an unreviewed feature branch.

## 1. Locked V1 behavior

The release candidate includes:

- Trusted Nearby discovery with saved-device fallback and privacy-safe approximate location.
- Trusted chat previews with mixed current/legacy conversation repair.
- Encrypted account-specific local chat history.
- Seven-day cloud retention for new private messages while downloaded history remains on the device.
- Profile photo add, change, remove and display.
- Private compressed photo messages.
- Private compressed video messages with a maximum duration of two minutes.
- Authenticated media download without public download URLs.
- Receiver download acknowledgement followed by cloud-media cleanup.
- Encrypted pending-upload recovery when confirmation is uncertain.
- Delete-for-me local file cleanup.
- Trusted 60-minute Unsend with immediate media deletion and scheduled cleanup retry.
- Account deletion cleanup for the encrypted database, cache and private local media.

A device-local history cannot be recovered after app-data clearing, uninstalling or losing the device unless a separate encrypted backup feature is added later.

## 2. One-time GitHub setup

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

Paste the output directly into the GitHub environment secret. Do not paste it into issues, pull requests, chat or logs.

## 3. Versioning rule

The single release version source is `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- `1.0.0` becomes Android `versionName`.
- `1` becomes Android `versionCode`.
- Every Play upload must use a versionCode greater than every previously uploaded build.
- Increase the version before triggering a new production AAB, including rejection fixes and internal-test replacements.

The Android Gradle configuration reads both values from Flutter. Do not hardcode them in `android/app/build.gradle.kts`.

## 4. Required green gates

Before Firebase deployment or a signed artifact, confirm the latest `main` quality run passed:

- Dart formatter and Flutter analyze.
- Flutter unit/widget tests.
- Debug APK build.
- Firestore and Cloud Storage emulator security tests.
- Cloud Functions tests and secure module loading.
- Unsigned release-build refusal.

Also confirm:

- All intended pull requests are merged.
- No emergency security fix remains open.
- `git status` is clean on the deployment PC.
- The local commit exactly matches `origin/main`.

## 5. Firebase production deployment

Run from the repository root on the verified `main` commit.

```powershell
cd F:\NearMeU
git fetch --prune origin
git switch main
git reset --hard origin/main

firebase login
firebase use nearmeu-e82c7

npm ci --prefix functions --no-audit --no-fund
npm test --prefix functions
flutter pub get
flutter test
```

Deploy in this order so indexes and rules are available before the new callable and scheduled functions receive traffic:

```powershell
firebase deploy --only firestore --project nearmeu-e82c7
firebase firestore:indexes --project nearmeu-e82c7
firebase deploy --only storage --project nearmeu-e82c7
firebase deploy --only functions --project nearmeu-e82c7
```

The configured Firebase resources are:

- `firestore.rules`
- `firestore.indexes.json`
- `storage.rules`
- Cloud Functions loaded from `functions/bootstrap.js`

After deployment, verify that these callable/scheduled capabilities exist in `asia-south1` where applicable:

- Trusted private-message sending.
- Trusted chat previews and legacy repair.
- Trusted Nearby candidates.
- Private media-message creation.
- Receiver media-download acknowledgement.
- Seven-day private-message purge.
- Trusted private-message Unsend.
- Pending private-media deletion retry.

Do not edit production Firestore or Storage rules only in the Firebase console. CLI deployment overwrites console rules, so the repository files remain the source of truth.

## 6. Firebase console checks

Before enabling a Play internal test:

1. Confirm all required Firestore indexes show `Enabled`; do not proceed while a new index is still building.
2. Register the Play signing and upload certificate SHA-256 fingerprints in Firebase.
3. Confirm Google Sign-In works with the Play-distributed certificate.
4. Register and validate Firebase App Check Play Integrity for `com.nearmeu.nearmeu`.
5. Confirm App Check enforcement does not lock out the intended internal-test build.
6. Confirm Cloud Storage rules show the repository deployment timestamp.
7. Confirm FCM, Crashlytics, Analytics and Performance use `nearmeu-e82c7`.
8. Confirm scheduled functions have a successful first invocation or no-error health state.

## 7. Build the signed AAB

From GitHub Actions:

1. Open **Build signed production AAB**.
2. Select **Run workflow** on the `main` branch.
3. Approve the `production-release` environment review.
4. Confirm the workflow validates the version, decodes the private keystore, verifies the alias, builds an obfuscated release AAB, verifies the bundle signature and removes signing files.

Download and retain both workflow artifacts:

- Signed AAB, SHA-256 checksum and release metadata.
- Dart obfuscation symbols for that exact version and commit.

Verify the downloaded AAB checksum before upload:

```bash
sha256sum -c app-release.aab.sha256
```

## 8. Google Play internal testing

Upload the AAB to the internal-testing track first. Complete or verify:

- App name, icon, feature graphic, phone screenshots, short description and full description.
- Privacy policy URL.
- Data safety declarations for location, account/profile data, messages, photos/videos, diagnostics, analytics, app performance and fraud/security use.
- Disclosure that chat history is primarily retained on the user's device and old cloud messages expire.
- App access instructions if review requires an authenticated flow.
- Content rating questionnaire.
- Target audience and age declarations.
- Ads declaration.
- Account deletion disclosure and working in-app deletion path.
- Contact details and release notes.

Do not promote directly to production after the first successful upload.

## 9. Two-device acceptance test

Install only from Google Play internal testing and test with two physical Android devices and two separate adult accounts.

### Account and profile

- Fresh install and Google Sign-In.
- Profile completion and permissions denied/allowed paths.
- Profile photo add, change and remove.
- Logout/login and account switching.

### Nearby and presence

- Nearby candidate loading for both accounts.
- Any-distance and explicit-radius behavior.
- Saved Nearby list when the network is unavailable.
- Background/foreground presence and admin online counts.
- Blocked/suspended accounts do not appear incorrectly.

### Text and legacy chat

- Two-way text, emoji, reply, seen and notification opening.
- Recent and older conversations appear together in Chats.
- A legacy parent chat is repaired without duplicating the conversation.
- Local history remains visible after temporarily disabling the network.
- Reopen the app and confirm local history remains.

### Photo and video

- Send gallery and camera photos in both directions.
- Send short and near-two-minute compressed videos in both directions.
- Verify upload progress and retry behavior.
- Receiver downloads successfully and can open/play the local file.
- Unrelated accounts cannot read private media.
- After receiver acknowledgement, confirm the cloud object is deleted or queued for cleanup.
- Confirm the downloaded local copy remains available after cloud cleanup.

### Message actions and retention

- Unsend text, photo and video within 60 minutes.
- Confirm Unsend removes local sender media and cloud media.
- Confirm an Unsend attempt after 60 minutes is rejected.
- Delete for me removes the local message and local files only for that account.
- Confirm new messages carry the seven-day retention policy.
- Do not wait seven days manually; verify scheduled-function logs and use emulator/unit coverage for the expiry boundary.

### Account deletion and observability

- Account deletion removes the encrypted local database, caches and private local media.
- Block/unblock, report limits and suspension handling.
- Play Integrity App Check, Crashlytics non-fatals, Analytics navigation and Performance startup trace.
- No email, raw UID, exact coordinates, token, profile name, message text or media path appears in telemetry dashboards.

Record the tested AAB SHA-256, commit, version, devices, Android versions, Firebase project, test accounts and result.

## 10. Promotion decision

Promote to closed testing only when there are no launch-blocking crashes, authentication failures, message-delivery failures, broken media downloads, privacy leaks, retention failures or App Check rejection loops.

Promote to production gradually and watch Crashlytics, ANRs, login success, notification delivery, function errors, Storage usage, retention cleanup and account deletion.

If Google Play rejects a release, fix the stated issue, increment the versionCode, build a new signed AAB through the same workflow and submit again. Keep every uploaded artifact and its symbol set traceable to its Git commit.
