# NearMeU release acceptance checklist

Use this checklist before distributing any APK/AAB or promoting a Google Play release. GitHub Actions is authoritative for automated checks; the physical-device and console checks below still require an operator.

## 1. Automated quality gate

- [ ] `flutter pub get` completes with the committed lockfile.
- [ ] Changed Dart files pass `dart format --output=none`.
- [ ] `flutter analyze` completes without compile errors.
- [ ] `flutter test` passes.
- [ ] Cloud Functions unit tests pass.
- [ ] Firestore and Storage emulator rule tests pass.
- [ ] Debug APK builds successfully.
- [ ] Unsigned release builds are refused.
- [ ] Production configuration validation passes.

## 2. Firebase and Google Sign-In

- [ ] Android package is `com.nearmeu.nearmeu` everywhere.
- [ ] `google-services.json` belongs to Firebase project `nearmeu-e82c7`.
- [ ] Google provider is enabled in Firebase Authentication.
- [ ] Debug, upload-key, and Play App Signing SHA-1/SHA-256 fingerprints are registered as applicable.
- [ ] The signed release metadata fingerprints match the intended upload key.
- [ ] App Check debug token is registered for debug testing.
- [ ] Play Integrity is configured before enforcing App Check for production.
- [ ] Firestore indexes, rules, Storage rules, and Functions are deployed from the reviewed revision.

## 3. Physical Android acceptance

Test with two adult accounts on two physical Android devices:

- [ ] Fresh install and Google Sign-In complete without `ApiException: 10`.
- [ ] New-account onboarding and existing-account login both work.
- [ ] Profile create/edit/photo flows work.
- [ ] Location permission denial, retry, and successful nearby discovery behave correctly.
- [ ] Text, reply, emoji, photo, video, and voice-message flows work.
- [ ] Unread counts clear only for the opened conversation.
- [ ] Presence and last-seen states recover after backgrounding/reopening.
- [ ] Block, unblock, report, suspension, logout, and account deletion work.
- [ ] Push notifications open the intended destination without exposing private message text.
- [ ] Support announcements and HTTPS links open correctly.
- [ ] App restart, offline mode, reconnect, and local chat recovery do not lose preserved media.
- [ ] Screenshot protection and forced-version gate behave as intended.

## 4. Signed release artifact

- [ ] Version in `pubspec.yaml` is unique and production-appropriate.
- [ ] Signed AAB is built only from `main` through the protected production workflow.
- [ ] `jarsigner -verify -certs` succeeds.
- [ ] AAB SHA-256 checksum and release metadata are retained.
- [ ] Dart obfuscation symbols are archived securely.
- [ ] No keystore, passwords, service-account credentials, `.env` secrets, user exports, or local databases are committed or uploaded as artifacts.

## 5. Google Play and legal operations

- [ ] Play App Signing and upload-key certificates are recorded and backed up.
- [ ] Closed Testing is used before production rollout.
- [ ] Privacy Policy, Terms, Community Guidelines, support contact, and account-deletion instructions are final.
- [ ] Data safety, target audience, content rating, and adults-only positioning are accurate.
- [ ] Crashlytics, Functions logs, budget alerts, abuse handling, backups, and support ownership are active.
- [ ] Rollback owner and rollback procedure are known before rollout.

## Release decision

A release is accepted only when every applicable automated, device, Firebase, signing, Play Console, legal, and operational item is complete. A green code build alone is not production approval.
