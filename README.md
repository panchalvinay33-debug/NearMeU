# NearMeU

NearMeU is an Android-first Flutter application for privacy-aware nearby discovery and private one-to-one messaging.

## Current project state

NearMeU is now on one direct path: **stabilize the current V1 and launch it**.

| Item | Value |
|---|---|
| Active launch branch | `v1/testing-baseline` |
| Launch phase | `V1 LAUNCH STABILIZATION` |
| Android package | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| Final launch commit | Freeze after launch checklist passes |
| Final launch APK/AAB hash | Freeze after release-candidate acceptance |
| Work after V1 launch | `V2 AFTER V1 LAUNCH` |

The current launch branch and the live Firebase backend are being kept aligned as one V1 system. Old batch-labelled roadmaps and later experimental feature lines are not the current source of truth.

## Start here

1. [`docs/V1_LAUNCH_CHECKLIST.md`](docs/V1_LAUNCH_CHECKLIST.md) — active launch gates and current verified state.
2. [`docs/MASTER_PROJECT_AUDIT.md`](docs/MASTER_PROJECT_AUDIT.md) — current V1 audit and recovery/verification rules.
3. [`docs/INDEX.md`](docs/INDEX.md) — documentation map.
4. [`config/project_state_manifest.json`](config/project_state_manifest.json) — machine-readable V1 launch state.
5. [`docs/V2_AFTER_LAUNCH.md`](docs/V2_AFTER_LAUNCH.md) — scope boundary for all non-launch work.

## Current V1 scope

The current base includes:

- Firebase Authentication and adult-only onboarding;
- Nearby discovery and distance filtering;
- online/offline presence and last-seen;
- one-to-one private chat;
- text, emoji, reply, photo, video and voice-message flows;
- message delivery/read infrastructure;
- encrypted local-first chat storage;
- block, report and owner-admin controls;
- Firestore and Storage rules/indexes;
- Firebase Cloud Functions;
- App Check debug testing and Play Integrity release configuration;
- Android signing/build workflows.

## Launch-stability work still open

Only four behavior groups are currently allowed to drive V1 runtime changes:

1. delivery/read/unread tick truth;
2. one-account identity with deactivation/reactivation continuity;
3. `users` / `privateProfiles` consistency and safe legacy migration;
4. one consistent online/offline/last-seen/green-dot truth across Nearby, Chats and Chat screen.

See [`docs/V1_LAUNCH_CHECKLIST.md`](docs/V1_LAUNCH_CHECKLIST.md) for exact acceptance requirements.

## Scope rule

Until V1 launches, do not add unrelated features or revive old future roadmaps. Fix only launch blockers and the accepted stability checklist.

After V1 launch, new product work will be planned fresh as **V2**. The current repository deliberately does not prescribe a detailed V2 feature sequence.

## Local validation

```powershell
flutter pub get
flutter analyze
flutter test
```

Cloud Functions and Firebase rules must also pass their repository tests before a launch candidate is accepted.

## Important external-state limitation

GitHub stores source, rules, functions, workflows and project documentation. It does not store secret values, the permanent keystore, Firebase Console state, App Check debug tokens, Play Console configuration, test-account credentials or live production data. Those remain in protected owner-controlled systems.