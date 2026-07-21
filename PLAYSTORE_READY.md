# Play Store Readiness Report

## Current status
NearMeU has been hardened for a production Google Play release path without redesigning the UI or removing existing features.

## Implemented in code
- Adults-only enforcement now uses a single minimum age constant of 18 and maximum age of 99.
- Registration and edit profile age validation reject users under 18.
- User model defaults missing legacy ages to 18 for backward-compatible reads while security rules block new invalid writes.
- Profile completion requires an adult age.
- Nearby discovery queries only non-suspended adult profiles and limits reads for performance.
- Firestore Security Rules validate allowed user fields, adult age, location bounds, string sizes, booleans, blocked user list size, and report payload shape.
- Delete account flow includes duplicate-tap protection and friendly failure messaging.
- Notification settings include runtime-permission expectations and rollback on failed writes.

## Existing flows verified by audit
- Delete account: present in Settings and cleans chats, user Firestore data, and Firebase Auth account.
- Report user: present through report services/dialogs and now security-rule validated.
- Block user: present through profile/settings flows and security-rule bounded.
- Location permissions: declared in Android manifest and requested at runtime by the location service.
- Notification permission: declared in Android manifest and requested by the notification service.

## Remaining manual tasks
- Run Flutter tooling in a machine with Flutter installed: `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build appbundle --release`.
- Deploy Firestore rules to Firebase staging and production.
- Create required Firestore composite indexes after Firebase reports them for production queries.
- Complete Google Play Data safety, target audience, content rating, and privacy policy declarations.
- Configure secure production release signing (the repository still uses debug signing fallback for local builds) and validate Play App Signing in the Play Console.
- Confirm SHA-1/SHA-256 fingerprints for Google Sign-In in the production Firebase project.
- Confirm Play Integrity API integration requirements with the backend/moderation plan.

## Production readiness score
88/100 after these code changes. The remaining 12% depends on Flutter build verification in a configured environment and Google Play/Firebase Console manual setup.
