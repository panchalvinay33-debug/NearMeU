# NearMeU

NearMeU is a Flutter-based nearby discovery and private chat application backed by Firebase.

## Current stack

- Flutter / Dart
- Firebase Authentication
- Cloud Firestore
- Cloud Functions (Node.js 20, region `asia-south1`)
- Firebase App Check
- Firebase Messaging and local notifications

## Main features

- Adult user onboarding and profiles
- Privacy-safe nearby discovery
- Distance, gender, activity and search filters
- Private one-to-one chats
- Trusted Cloud Function message sending
- Trusted chat-inbox and nearby-candidate reads
- Blocking, reporting, suspension and moderation controls
- Presence, last-seen and unread indicators

## Local setup

1. Install Flutter and Android SDK.
2. Connect the Firebase Android app configuration.
3. From the repository root run:

```powershell
flutter pub get
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter run
```

## Firebase deployment

```powershell
firebase deploy --only "firestore:rules,firestore:indexes" --project nearmeu-e82c7

$env:FUNCTIONS_DISCOVERY_TIMEOUT="120"
firebase deploy --only functions --project nearmeu-e82c7
Remove-Item Env:FUNCTIONS_DISCOVERY_TIMEOUT
```

## Repository policy

- `main` is the single source of truth.
- Temporary development branches should be deleted after their work reaches `main`.
- Generated builds, local SDK settings, signing files, service-account files and local backup folders must not be committed.
