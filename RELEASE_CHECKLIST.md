# NearMeU Release Checklist

Use this checklist before every Google Play production release.

## Automated/code checks
- [ ] Run `flutter pub get`.
- [ ] Run `flutter analyze` and confirm zero errors and zero warnings.
- [ ] Run `flutter test`.
- [ ] Build Android App Bundle with `flutter build appbundle --release`.
- [ ] Deploy and validate `firestore.rules` in a Firebase test or staging project.
- [ ] Smoke test Google Sign-In, registration, edit profile, nearby users, chat, report, block, unblock, notifications, logout, and delete account.

## Firebase
- [ ] Confirm Android package name and SHA-1/SHA-256 fingerprints are configured for Google Sign-In.
- [ ] Confirm `google-services.json` belongs to the intended production Firebase project.
- [ ] Confirm Firestore indexes required by nearby and reports queries are created.
- [ ] Confirm Firebase Authentication providers and authorized domains are production-ready.
- [ ] Confirm FCM sender ID and notification channel are valid.

## Google Play Console
- [ ] Complete Data safety form accurately for profile, location, chats, reports, identifiers, and diagnostics.
- [ ] Publish Privacy Policy URL.
- [ ] Confirm app content rating is adults-only/18+ where applicable.
- [ ] Confirm target audience excludes children.
- [ ] Add account deletion instructions and in-app delete account availability.
- [ ] Upload signed Android App Bundle.
- [ ] Replace debug signing fallback with production release signing in CI/local secure properties before uploading.
- [ ] Verify Play App Signing and release signing keys.
- [ ] Review Play Integrity API setup if abuse controls require server verification.

## Manual legal/content review
- [ ] Legal review of Terms & Conditions, Privacy Policy, and Community Guidelines.
- [ ] Moderation workflow review for user reports and suspended users.
- [ ] Support contact and response SLA review.
