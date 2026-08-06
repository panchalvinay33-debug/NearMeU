# Batch 09 R2 — Clean Audio Calling Restart

Status: 09-R2-A2 IMPLEMENTED / FRESH CI RETRIGGERED

Base: current `main` at branch creation time.

Superseded references preserved for recovery only:
- PR #103 — original Batch 09 Agora audio calling
- Working client checkpoint: `8898cb48353751ddd39ea8601eedd63b403c880b`
- PR #108 — attempted safe call-history patch

Permanent build/version policy:
- `docs/BUILD_AND_VERSION_POLICY.md`

## Why R2 exists

A physically working audio-call checkpoint was later destabilized while adding call history. The original and corrective branches are preserved for forensic comparison, but no further development should continue on them. R2 rebuilds audio calling from clean current `main` using small acceptance-gated slices.

## Non-negotiable safety rules

1. Existing Nearby, Chats, text/photo/video/voice messaging, profile sharing, Premium recovery, account lifecycle and Admin backend behavior must remain unchanged unless a slice explicitly requires a minimal integration point.
2. Each slice must pass CI before an APK is built for owner testing.
3. Each physically accepted slice gets an immutable checkpoint before the next slice starts.
4. A later slice failure must be reversible without resetting earlier accepted calling slices.
5. Call history is the final slice and must not be allowed to destabilize call establishment or existing chat behavior.
6. No Agora secret may be committed to source, docs, logs or screenshots. Existing Firebase Secret Manager values remain authoritative.
7. No video/camera work is allowed in Batch 09 R2.
8. A successfully tested/accepted APK must be reused when source, build configuration, dependencies, signing, architecture and version identity have not changed. Do not repeat the full Flutter/Gradle/Agora native rebuild merely to obtain the same binary again.
9. Every owner-distributed APK must have a visible version identity before installation via its filename and after installation inside NearMeU.
10. APK handoff filenames must include version name, build number, architecture and build type; ambiguous names such as only `app-release.apk` are compiler outputs, not final owner-facing artifact names.

## Version identity requirement

Current branch version source of truth is `pubspec.yaml`:

`version: 1.0.11+12`

This means:
- version name: `1.0.11`;
- build/version code: `12`.

Required owner-facing artifact naming examples:
- `NearMeU-v1.0.11-b12-universal-release.apk`
- `NearMeU-v1.0.11-b12-arm64-release.apk`
- `NearMeU-v1.0.11-b12-arm64-release.zip`

Before installation, the filename must make the exact build obvious. After installation, NearMeU must show at minimum `NearMeU version 1.0.11` and `Build 12` in Settings/About or an equivalent stable screen. Runtime package metadata must be read using `package_info_plus`; do not maintain a second hard-coded version string in the UI.

Every accepted APK checkpoint should record commit SHA, version/build, architecture, build type, signing identity/fingerprint reference, artifact SHA-256, CI run and physical-test state.

## Current R2-A checkpoint

Implemented without consumer-app changes:
- fresh isolated `audioCallsR2` and `activeAudioCallsR2` backend collections;
- Premium-only server-authorized initiation;
- active-profile, suspension, bidirectional block and overlap checks;
- ringing / accepted / declined / ended / missed / expired lifecycle;
- stale active-call cleanup;
- exact `agora-token` version `2.0.5` with generated lockfile;
- separate participant-only `getAudioRtcAccessR2` callable;
- short-lived RTC credentials generated from Firebase Secret Manager values;
- callee RTC denial before acceptance;
- terminal, expired, blocked and suspended-call RTC denial;
- focused Node source/security contract tests;
- controlled deployment script limited to R2 backend functions.

Still intentionally not added:
- no Flutter/Android calling UI;
- no Nearby or Chats integration;
- no incoming-call notification integration;
- no call history;
- no mute/speaker extras;
- no video.

Quality Gate #577 passed backend, Firestore, Dart analysis and Flutter tests but became abnormally stuck during the debug APK build. A harmless documentation checkpoint retriggers a fresh full Quality Gate; R2-B implementation remains blocked until that new run completes green.

## Slice plan

### 09-R2-A — Backend contract only
- Trusted short-lived Agora token issuance.
- Premium-only call initiation.
- Free/Premium incoming receive participation.
- Active-profile, suspension, bidirectional block and overlapping-call checks.
- Ringing / accepted / declined / ended / missed / expired lifecycle.
- Stale active-call cleanup.
- No consumer UI changes except what is strictly required later.

Gate: backend tests + security tests + controlled deployment evidence.

### 09-R2-B — Minimal physical call
- Audio Call entry point.
- Ringing screen.
- Incoming accept/decline screen.
- Join same Agora channel.
- Two-way audible audio.
- End call from either side.

Gate: two-phone physical PASS. Immediately create accepted calling checkpoint before any extra feature.

### 09-R2-C — Call controls and cleanup
- Mute/unmute.
- Speaker routing.
- Decline.
- Missed/timeout.
- Stale lock self-heal.
- Simultaneous-call rejection.
- Microphone permission failure path.

Gate: focused two-phone physical PASS + checkpoint.

### 09-R2-D — Incoming notification lifecycle
- Foreground incoming call.
- Background/warm-start incoming call.
- Cold-start authenticated shell queueing.
- Deduplicated navigation.

Gate: physical PASS for all three app states + checkpoint.

### 09-R2-E — Call history only
- Server-owned deterministic history entry after terminal call state.
- Completed / declined / missed / expired outcomes.
- Backend-derived duration where applicable.
- Idempotent write; no duplicates.
- Existing normal message pipeline must not be repurposed in a way that changes Nearby/Chats/calling behavior.

Gate: call history physical PASS plus full regression smoke of Nearby, Chats, text, photo/video/voice messages and calling. If this slice fails, revert only this slice.

## Final acceptance

Batch 09 R2 may merge only after:
- all CI is green on final head;
- permanently signed direct-update APK is produced;
- owner-facing APK/ZIP uses the mandatory versioned filename convention;
- the installed app shows its exact runtime version/build in Settings/About;
- version/build metadata matches the distributed APK filename;
- accepted/tested APK artifacts are reused rather than unnecessarily rebuilt when their inputs are unchanged;
- two-device physical matrix passes;
- existing app data/login/history survive update;
- accepted checkpoints are recorded with commit + version/build + architecture + digest;
- production functions correspond exactly to the accepted source;
- owner explicitly accepts the final result.

Until then Batch 08 remains the last fully accepted consumer recovery base.
