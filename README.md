# NearMeU

NearMeU is an adults-only nearby social chat application built with Flutter and Firebase. The V1 product focuses on private one-to-one text chat, mutually compatible nearby discovery, blocking/reporting, official support announcements, and an administrator moderation workflow.

## V1 principles

- Adults only: profiles must contain a verified-in-app age from 18 to 99.
- Privacy first: the UI exposes rounded distance and broad state-level location only.
- Mutual discovery: a profile appears only when both users' gender preferences are compatible.
- Safety by default: blocking, reporting, suspension enforcement, and strict Firestore rules are release requirements.
- No production secrets in Git: upload keys, service accounts, and local configuration remain outside the repository.

## Technology

- Flutter / Dart
- Firebase Authentication with Google Sign-In
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions for Firebase

## Local setup

1. Install the current stable Flutter SDK and Java 17.
2. Add the intended Firebase project's `android/app/google-services.json`.
3. Run:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

Firestore rule tests require Node.js 20 and the Firebase CLI:

```bash
npm install
firebase emulators:exec --only firestore "npm run test:rules"
```

## Android release signing

Release builds deliberately fail when `android/key.properties` is missing. Never commit the upload keystore or its passwords.

Example local `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/nearmeu-upload.jks
```

Build the Play Store bundle with:

```bash
flutter build appbundle --release
```

## Firebase deployment

Deploy rules, indexes, and functions only after tests pass against the intended staging project:

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## Release process

Use `RELEASE_CHECKLIST.md` before every Play Console upload. Production releases require zero analyzer warnings, passing Flutter and Firestore-rule tests, two-device chat testing, secure signing, accurate Data Safety declarations, public legal URLs, and verified account deletion.
