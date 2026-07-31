# NearMeU

NearMeU is an Android-first Flutter application for privacy-aware nearby discovery and private one-to-one messaging.

## Current accepted state

| Item | Value |
|---|---|
| Source of truth | `main` |
| Recovery branch | `stable/official-recoverable-base` |
| Accepted commit | `f9bc38572c715a017c8b261a5d805aa125ffe7a5` |
| Android package | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| Tested APK SHA-256 | `587CD1B328A1CAEB659A0C5D0604609C5E6A381B61EFC6D0ACD9D3C2B1BDE00C` |
| Long-lived branches | `main`, `stable/official-recoverable-base` |
| Production release | Not yet complete |

The accepted base was installed on the owner's Android phone with update mode and verified for the restored login, App Check registration, Nearby access and chat access. `main` and the recovery branch are identical at the accepted state.

## Start here

| Need | Document |
|---|---|
| Complete audit, PC details, backup, roadmap and current truth | [`docs/MASTER_PROJECT_AUDIT.md`](docs/MASTER_PROJECT_AUDIT.md) |
| Exact recovery process and acceptance rules | [`docs/OFFICIAL_RECOVERABLE_BASE.md`](docs/OFFICIAL_RECOVERABLE_BASE.md) |
| Documentation map | [`docs/INDEX.md`](docs/INDEX.md) |
| Machine-readable state | [`config/project_state_manifest.json`](config/project_state_manifest.json) |
| Production release work | [`docs/PRODUCTION_RELEASE_RUNBOOK.md`](docs/PRODUCTION_RELEASE_RUNBOOK.md) |
| Physical Android testing | [`docs/ANDROID_PHONE_SMOKE_TEST.md`](docs/ANDROID_PHONE_SMOKE_TEST.md) |
| Security and secret handling | [`SECURITY.md`](SECURITY.md) |

## Included in the current base

- Firebase Authentication and adult-only onboarding
- Nearby discovery and distance filtering
- presence, last-seen, unread, block, report and account controls
- private text, emoji, reply, photo, video and voice-message flows
- encrypted local-first chat storage
- Firestore and Storage security rules and emulator tests
- Cloud Functions source and tests
- permanent Android signing through protected GitHub Actions secrets
- Google Sign-In-compatible signing identity
- App Check debug testing and Play Integrity release configuration
- quality-gate and recoverable-APK workflows

## Known remaining work

- analyzer warning and technical-debt cleanup
- full two-device regression testing
- reliability validation for weak network, restart, logout and account switching
- premium voice/video calling and one-plan entitlement design
- production Firebase verification
- Play Integrity production acceptance
- legal URLs and Play Console declarations
- internal/closed testing and controlled production rollout

The active release checklist is tracked in issue #41 and the master audit roadmap.

## Repository structure

```text
android/                 Android configuration
config/                  Machine-readable project state
functions/               Firebase Cloud Functions and tests
lib/                     Flutter application code
rules_tests/             Firebase emulator security tests
test/                    Flutter tests
docs/                    Audit, architecture, release and recovery docs
.github/workflows/       CI and signed-build workflows
```

## Local validation

```powershell
flutter pub get
flutter analyze
flutter test
```

The accepted source currently has existing analyzer warnings/informational lints. These are tracked technical debt; tests and required CI gates pass.

## Safe future workflow

1. Start from current `main`.
2. Create one focused short-lived branch.
3. Make the smallest necessary change.
4. Open a pull request and pass all required checks.
5. Test runtime/config changes on a physical Android phone.
6. Obtain owner approval.
7. Merge, update recovery/audit records and delete the temporary branch.
8. Move the recovery branch only after accepted device testing.

## Important external-state limitation

GitHub is the source of truth for code, architecture, roadmap and recovery instructions. It intentionally does not store secret values, the permanent keystore file, Firebase Console state, App Check debug tokens, Play Console configuration, test-account credentials or live production data. Those remain in protected secrets, encrypted owner backups and the relevant consoles.
