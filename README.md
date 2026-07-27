# NearMeU

NearMeU is an Android-first Flutter application for privacy-aware nearby discovery and private one-to-one messaging. The current product baseline intentionally ships **without voice/video calling, paid subscriptions, or iOS support**.

> **Repository status:** this repository contains the complete non-calling V1 baseline, its Firebase backend, security rules, automated quality gates, release process, database-state manifest, backup plan, and remaining launch checklist.

## Start here

| Need | Document |
|---|---|
| Understand the final product baseline | [`docs/final/NEARMEU_FINAL_BASELINE.md`](docs/final/NEARMEU_FINAL_BASELINE.md) |
| See what is complete and what remains | [`docs/final/ROADMAP_AND_RELEASE_PLAN.md`](docs/final/ROADMAP_AND_RELEASE_PLAN.md) |
| Back up or recover production data | [`docs/final/BACKUP_AND_RECOVERY_PLAN.md`](docs/final/BACKUP_AND_RECOVERY_PLAN.md) |
| Read the machine-readable project state | [`config/project_state_manifest.json`](config/project_state_manifest.json) |
| Deploy Firebase safely | [`docs/PRODUCTION_RELEASE_RUNBOOK.md`](docs/PRODUCTION_RELEASE_RUNBOOK.md) |
| Test on physical Android phones | [`docs/ANDROID_PHONE_SMOKE_TEST.md`](docs/ANDROID_PHONE_SMOKE_TEST.md) |
| Review all documentation by topic | [`docs/INDEX.md`](docs/INDEX.md) |

## Product scope

### Included

- Firebase Authentication and adult-only onboarding
- Public discovery profiles separated from owner-only private account data
- Privacy-rounded nearby discovery with distance/search filtering
- Presence, last-seen, unread counts, block/report/suspension controls
- Private text, reply, emoji, photo, compressed video, and voice-message flows
- Encrypted local-first chat storage and offline recovery
- Seven-day cloud message/media retention with verified local preservation
- Trusted Cloud Function sending, inbox reads, nearby reads, unsend, cleanup, and moderation
- Privacy-safe private-chat push notifications
- Official NearMeU Support announcements and announcement push routing
- Screenshot protection, forced-update gate, App Check, Play Integrity, Crashlytics, Analytics, and Performance Monitoring
- Account deletion through a trusted backend with retry-safe cleanup
- Firebase rules, indexes, Functions tests, Flutter tests, APK CI artifacts, and signed-AAB release safeguards

### Deliberately deferred

- Voice calling
- Video calling
- Paid plans or in-app purchases
- iOS release

Deferred items are not partially enabled and must be introduced later as separately designed, costed, tested releases.

## Architecture

```text
Flutter Android app
  ├─ Firebase Authentication
  ├─ Firebase App Check / Play Integrity
  ├─ Cloud Firestore
  │   ├─ public discovery profiles
  │   ├─ private account profiles
  │   ├─ chats/messages
  │   ├─ announcements/read state
  │   └─ backend-only safety/cleanup state
  ├─ Cloud Functions (Node.js 20, asia-south1)
  │   ├─ trusted chat/media operations
  │   ├─ notification delivery
  │   ├─ retention/cleanup workers
  │   └─ account deletion/moderation
  ├─ Firebase Storage
  │   ├─ profile photos
  │   └─ temporary private chat media
  └─ encrypted app-private local database/media
```

## Repository structure

```text
android/                 Android application and release configuration
config/                  Machine-readable project-state manifest
functions/               Firebase Cloud Functions and Node tests
lib/                     Flutter application code
  models/                Domain models
  screens/               App screens
  security/              Client security and routing guards
  services/              Firebase, local-data, messaging and domain services
  theme/                 Centralized design system
  widgets/               Reusable UI components
rules_tests/             Firebase emulator security tests
storage.rules            Firebase Storage security policy
firestore.rules          Firestore security policy
firestore.indexes.json   Required indexes
docs/                    Architecture, testing, release, legal and recovery docs
test/                    Flutter unit/widget/source-contract tests
.github/workflows/       Authoritative CI and protected release workflows
```

## Local development

Requirements:

- Flutter SDK compatible with `pubspec.lock`
- Android SDK and Java version used by CI
- Firebase CLI
- Node.js 20 for Cloud Functions
- A Firebase Android configuration for the intended project

```powershell
cd F:\NearMeU
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
flutter run
```

For a debug APK:

```powershell
flutter build apk --debug
```

Debug builds use the Firebase App Check debug provider. Register the emitted debug token in Firebase before testing protected backend calls.

## Backend validation

```powershell
cd F:\NearMeU\functions
npm ci
npm test

cd F:\NearMeU
npm ci
firebase emulators:exec --only firestore,storage "npm run test:rules"
```

GitHub Actions is the authoritative quality gate and validates formatting, analysis, Flutter tests, Functions tests, Firebase rules, debug APK creation, and refusal of unsigned production releases.

## Firebase deployment

Use the exact order and verification steps in the production runbook. High-level commands:

```powershell
firebase deploy --only "firestore:rules,firestore:indexes,storage" --project nearmeu-e82c7

$env:FUNCTIONS_DISCOVERY_TIMEOUT="120"
firebase deploy --only functions --project nearmeu-e82c7
Remove-Item Env:FUNCTIONS_DISCOVERY_TIMEOUT
```

Deployment is separate from merging source code. A green GitHub build does not prove that the latest rules, indexes, Storage policy, or Functions are deployed.

## Project-state record

The canonical machine-readable state is in [`config/project_state_manifest.json`](config/project_state_manifest.json). It can be checked or stored in Firestore through the guarded admin script:

```powershell
cd F:\NearMeU\functions
npm run project-state:check

$env:NEARMEU_EXPECTED_FIREBASE_PROJECT_ID="nearmeu-e82c7"
npm run project-state:store
```

The write command creates/updates the controlled `systemProjectState` records. Run it only from a trusted admin environment.

## Release path

1. Merge only green, reviewed work into `main`.
2. Deploy Firebase rules, indexes, Storage policy, and Functions.
3. Store/update the project-state manifest in Firestore.
4. Complete the two-account/two-device physical test matrix.
5. Configure App Check/Play Integrity and production signing.
6. Build the signed obfuscated AAB using the protected workflow.
7. Publish through Play Console Closed Testing first.
8. Monitor Crashlytics, Functions logs, budget alerts, and user feedback before production rollout.

## Branch policy

- `main` is the only long-lived source-of-truth branch.
- Feature/fix branches must use a focused PR and be deleted after merge or closure.
- Do not continue work from old closed-PR branches.
- Release artifacts come from GitHub Actions, not from unverified local builds.
- Never commit signing keys, service-account credentials, Firebase admin credentials, `.env` secrets, local database copies, or exported user data.

## Current definition of complete

The non-calling V1 codebase is considered feature-complete when it is on `main` and the quality gate is green. Production launch still requires external Firebase deployment, real-device acceptance testing, owner-controlled legal/contact values, signing secrets, Play Console configuration, and verified backups. Those remaining operational steps are tracked in the final roadmap rather than hidden as unfinished application code.
