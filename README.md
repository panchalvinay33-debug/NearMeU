# NearMeU

NearMeU is an Android-first Flutter application for privacy-aware nearby discovery and private one-to-one messaging.

> **Current repository status (2026-07-30):** the permanent-signed Android baseline builds successfully in CI and has been physically verified for installation, Google Sign-In, App Check debug registration and Nearby discovery. `main` is protected by pull-request and required-check rules.

## Start here

| Need | Document |
|---|---|
| Canonical base, branch protection and external-state warning | [`docs/final/OFFICIAL_BASE_MARKER.md`](docs/final/OFFICIAL_BASE_MARKER.md) |
| Exact working state and signing identity | [`docs/final/CURRENT_VERIFIED_STATE.md`](docs/final/CURRENT_VERIFIED_STATE.md) |
| Recover the last known-good application | [`docs/final/RECOVERY_PLAYBOOK.md`](docs/final/RECOVERY_PLAYBOOK.md) |
| Rules for every future change | [`docs/final/CHANGE_CONTROL.md`](docs/final/CHANGE_CONTROL.md) |
| Lock, backup, architecture and roadmap blueprint | [`docs/final/FINAL_LOCK_BACKUP_BLUEPRINT.md`](docs/final/FINAL_LOCK_BACKUP_BLUEPRINT.md) |
| Product baseline | [`docs/final/NEARMEU_FINAL_BASELINE.md`](docs/final/NEARMEU_FINAL_BASELINE.md) |
| Remaining release work | [`docs/final/ROADMAP_AND_RELEASE_PLAN.md`](docs/final/ROADMAP_AND_RELEASE_PLAN.md) |
| Firebase/data backup and recovery | [`docs/final/BACKUP_AND_RECOVERY_PLAN.md`](docs/final/BACKUP_AND_RECOVERY_PLAN.md) |
| Machine-readable project state | [`config/project_state_manifest.json`](config/project_state_manifest.json) |
| Production deployment | [`docs/PRODUCTION_RELEASE_RUNBOOK.md`](docs/PRODUCTION_RELEASE_RUNBOOK.md) |
| Android smoke testing | [`docs/ANDROID_PHONE_SMOKE_TEST.md`](docs/ANDROID_PHONE_SMOKE_TEST.md) |
| Documentation index | [`docs/INDEX.md`](docs/INDEX.md) |
| Security and secret handling | [`SECURITY.md`](SECURITY.md) |

## Official recovery point

- Default branch: `main`
- Recovery branch: `stable/official-base-v1-2026-07-30`
- Base merge commit: `a743ffa407c145b3852c547d31f33458e8e839b4`
- Android package: `com.nearmeu.nearmeu`
- Permanent signing SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`

## GitHub protection

Every update to `main` must use a pull request and pass:

- `Flutter checks`
- `Firebase rules tests`
- `Cloud Functions checks`

Deletion and force-push are blocked for `main`.

## Product scope

### Included in the current baseline

- Firebase Authentication and adult-only onboarding
- nearby discovery and filtering
- presence, last-seen, unread counts, block/report/suspension controls
- private text, reply, emoji, photo, compressed video and voice-message flows
- encrypted local-first chat storage and offline recovery
- trusted Cloud Functions and Firebase security rules
- private push-notification architecture
- account deletion backend
- permanent Android signing and CI APK artifacts
- Firebase App Check debug testing and release Play Integrity configuration

### Deferred or operationally pending

- voice/video calling
- paid plans or in-app purchases
- iOS release
- Play Store closed testing and production rollout
- release App Check verification through Play Integrity
- full two-account/two-device acceptance
- screenshot-protection redesign
- forced-update-gate redesign

## Repository structure

```text
android/                 Android configuration
config/                  Machine-readable project state
functions/               Firebase Cloud Functions and tests
lib/                     Flutter application code
rules_tests/             Firebase emulator security tests
test/                    Flutter tests
docs/                    Architecture, release and recovery docs
.github/workflows/       CI and signed-build workflows
```

## Local validation

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
```

Backend checks:

```powershell
cd functions
npm ci
npm test

cd ..
npm ci
firebase emulators:exec --only firestore,storage "npm run test:rules"
```

## Safe future workflow

1. Start from current `main`.
2. Create one focused branch.
3. Make the smallest necessary change.
4. Open a pull request.
5. Wait for all required checks.
6. Test runtime changes on a physical Android phone.
7. Merge only after verification.
8. Delete the temporary branch after the merged result is stable.
9. Update verified-state, roadmap and recovery documentation for material changes.

## Important limitation

GitHub is the source of truth for code, architecture, roadmap and recovery instructions, but it intentionally does **not** store secret values, the permanent keystore file, Firebase Console state, App Check debug tokens, Play Console configuration or live production data. Those remain in GitHub Actions secrets, encrypted owner backups and the relevant consoles.

## Current definition of stable

The current permanent-signed non-calling V1 baseline is safe for continued development. Public production launch is not yet complete; the genuine remaining work is tracked in issues #41 and #68 and in the release roadmap.