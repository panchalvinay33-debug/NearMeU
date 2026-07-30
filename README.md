# NearMeU

NearMeU is an Android-first Flutter application for privacy-aware nearby discovery and private one-to-one messaging. The current product baseline intentionally ships **without voice/video calling, paid subscriptions, or iOS support**.

> **Verified repository status (2026-07-30):** the permanent-signed Android baseline builds successfully in CI and has been physically tested for installation, Google Sign-In, App Check debug registration and Nearby discovery. Start with the verified-state and recovery documents below before making changes.

## Start here

| Need | Document |
|---|---|
| See the exact working state, commit, CI run and signing identity | [`docs/final/CURRENT_VERIFIED_STATE.md`](docs/final/CURRENT_VERIFIED_STATE.md) |
| Recover the last known-good application | [`docs/final/RECOVERY_PLAYBOOK.md`](docs/final/RECOVERY_PLAYBOOK.md) |
| Understand rules for every future change | [`docs/final/CHANGE_CONTROL.md`](docs/final/CHANGE_CONTROL.md) |
| Read the final lock, backup and architecture blueprint | [`FINAL_LOCK_BACKUP_BLUEPRINT.md`](FINAL_LOCK_BACKUP_BLUEPRINT.md) |
| Understand the product baseline | [`docs/final/NEARMEU_FINAL_BASELINE.md`](docs/final/NEARMEU_FINAL_BASELINE.md) |
| See what is complete and what remains | [`docs/final/ROADMAP_AND_RELEASE_PLAN.md`](docs/final/ROADMAP_AND_RELEASE_PLAN.md) |
| Back up or recover production data | [`docs/final/BACKUP_AND_RECOVERY_PLAN.md`](docs/final/BACKUP_AND_RECOVERY_PLAN.md) |
| Read the machine-readable project state | [`config/project_state_manifest.json`](config/project_state_manifest.json) |
| Deploy Firebase safely | [`docs/PRODUCTION_RELEASE_RUNBOOK.md`](docs/PRODUCTION_RELEASE_RUNBOOK.md) |
| Test on physical Android phones | [`docs/ANDROID_PHONE_SMOKE_TEST.md`](docs/ANDROID_PHONE_SMOKE_TEST.md) |
| Review documentation by topic | [`docs/INDEX.md`](docs/INDEX.md) |
| Review security and secret-handling rules | [`SECURITY.md`](SECURITY.md) |

## Golden recovery point

- Commit: `48a290c58a14a71174b921832e516b568b06ba48`
- Stable branch: `stable/permanent-signed-2026-07-30`
- Backup branch: `backup/pre-final-lock-2026-07-30`
- Release branch: `release/permanent-signed-v1`
- Android package: `com.nearmeu.nearmeu`
- Permanent signing SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`

Do not delete or rewrite these recovery references until a newer release is physically verified and documented.

## Product scope

### Included and working in the current baseline

- Firebase Authentication and adult-only onboarding
- Public discovery profiles separated from owner-only private account data
- Privacy-rounded nearby discovery with distance/search filtering
- Presence, last-seen, unread counts, block/report/suspension controls
- Private text, reply, emoji, photo, compressed video, and voice-message flows
- Encrypted local-first chat storage and offline recovery
- Seven-day cloud message/media retention design with local preservation
- Trusted Cloud Function sending, inbox reads, nearby reads, unsend, cleanup, and moderation
- Privacy-safe private-chat push notification architecture
- Official NearMeU Support announcements and announcement push routing
- Firebase App Check debug testing, release Play Integrity configuration, Crashlytics, Analytics, and Performance Monitoring
- Account deletion through a trusted backend with retry-safe cleanup
- Firebase rules, indexes, Functions tests, Flutter tests, and permanently signed APK CI artifacts

### Deliberately deferred or operationally pending

- Voice calling
- Video calling
- Paid plans or in-app purchases
- iOS release
- Play Store closed-testing and production rollout
- Release App Check verification through Play Integrity
- Full two-account/two-device acceptance matrix
- Screenshot protection redesign (the previous broken wrapper was disabled)
- Forced-update gate redesign (the previous broken startup gate was disabled)

Deferred items are not partially enabled and must be introduced later as separately designed, costed and tested releases.

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
- Firebase Android configuration for project `nearmeu-e82c7`

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

Debug builds use the Firebase App Check debug provider. Register the generated debug token before testing protected backend calls. A reinstall or app-data reset may create a new token.

## Backend validation

```powershell
cd F:\NearMeU\functions
npm ci
npm test

cd F:\NearMeU
npm ci
firebase emulators:exec --only firestore,storage "npm run test:rules"
```

GitHub Actions is the authoritative quality gate and validates formatting, analysis, Flutter tests, Functions tests, Firebase rules, permanent signing restoration/certificate verification, and signed debug/release APK creation.

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

The write command creates or updates controlled `systemProjectState` records. Run it only from a trusted admin environment.

## Release path

1. Merge only green, reviewed work into `main`.
2. Deploy Firebase rules, indexes, Storage policy, and Functions.
3. Store/update the project-state manifest in Firestore.
4. Complete the two-account/two-device physical test matrix.
5. Test release App Check through Play Integrity on a Play testing track.
6. Build the signed obfuscated AAB using the protected workflow.
7. Publish through Play Console Closed Testing first.
8. Monitor Crashlytics, Functions logs, budget alerts, and user feedback before production rollout.

## Branch policy

- `main` is the only active source-of-truth branch.
- Stable/backup/release branches are recovery references and must not receive feature work.
- Feature/fix branches must use a focused PR and be deleted after merge or closure.
- Do not continue work from old closed-PR branches.
- Release artifacts come from GitHub Actions, not from unverified local builds.
- Never commit signing keys, service-account credentials, Firebase admin credentials, `.env` secrets, local database copies, or exported user data.

## Current definition of complete

The permanent-signed non-calling V1 baseline is stable for continued development: CI is green, permanent signing is configured, Google Sign-In and App Check debug testing work on a real Android phone, and a deterministic recovery point exists. Public production launch is not yet complete; remaining operational work is explicitly tracked in the roadmap and must not be mistaken for missing hidden code.
