# Batch 09 R2 — Clean Audio Calling Restart

Status: PLANNING / CLEAN RESTART

Base: current `main` at branch creation time.

Superseded references preserved for recovery only:
- PR #103 — original Batch 09 Agora audio calling
- Working client checkpoint: `8898cb48353751ddd39ea8601eedd63b403c880b`
- PR #108 — attempted safe call-history patch

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
- two-device physical matrix passes;
- existing app data/login/history survive update;
- accepted checkpoints are recorded;
- production functions correspond exactly to the accepted source;
- owner explicitly accepts the final result.

Until then Batch 08 remains the last fully accepted consumer recovery base.