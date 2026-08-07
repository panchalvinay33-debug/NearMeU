# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-08

Authoritative stability/recovery rules: `docs/ANDROID_STABILITY_AND_RECOVERY_RULEBOOK.md`.

## Current operating decision

- Original pre-calling Batch 08 merge `f83a6e92457f728f177dc062dcc9171c141a9217` is the recovery validation anchor.
- Recovery work is isolated on `recovery/original-batch08-android-stable`.
- Batch 08.1 is removed from the active development path and retained only as historical/reference evidence.
- Batch 09 audio calling is frozen. No Batch 09 code may be merged/reapplied until the recovered Android-stable base is owner accepted.
- Samsung and Motorola are representative physical test devices only. Product behavior must be generic Android behavior, not OEM-specific behavior.

## Governing rule

Every runtime change is one focused batch. A later batch starts only after all of the following:

1. Start from the latest owner-accepted stable/recovery base.
2. Use canonical workspace `F:\NearMeU`.
3. Use one isolated short-lived runtime branch.
4. Freeze scope before coding.
5. Do not mix feature work with unrelated compatibility/security changes.
6. Run Flutter, Firebase Rules and Cloud Functions checks as applicable.
7. Build with permanent Android signing.
8. Preserve package `com.nearmeu.nearmeu` and monotonic production versioning.
9. Physically test the new behavior and mandatory core regressions.
10. Test representative Android devices/networks without OEM-specific hacks.
11. Owner accepts or rejects the exact tested state.
12. Merge only through a passing PR.
13. Sync authoritative docs and evidence.
14. Create/record GitHub recovery point.
15. Create a complete PC stable-base backup under `F:\NearMeU_Stable_Backups`.
16. Verify the PC backup can identify/restore the exact commit and accepted artifact.
17. Promote the stable base.
18. Sync `F:\NearMeU` before starting the next runtime batch.

Skipping the PC backup or restore verification blocks the next batch.

## Recovery target

The immediate target is a new Android-stable recovered base derived from original Batch 08, with only minimum proven generic fixes required for current Firebase/backend/Android compatibility.

Original Batch 08:

- PR: `#100`
- Tested runtime: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Merged runtime: `f83a6e92457f728f177dc062dcc9171c141a9217`
- Version: `1.0.11+12`
- Scope: profile sharing and deep-link recovery; no calling.

This source state is a recovery anchor, not automatically a newly accepted stable base. It must pass the current backend audit and full physical regression matrix before promotion.

## Required recovery sequence

### Phase 1 — Freeze

- no calling/video/Admin feature work;
- no broad Firebase deployment;
- preserve current Batch 09 as reference only;
- do not use Batch 08.1 as a base.

### Phase 2 — Backend compatibility audit

Validate original Batch 08 against current:

- Google/Firebase Auth;
- Firebase App Check;
- callable Functions/regions;
- Firestore Rules;
- Storage Rules;
- FCM/notification requirements;
- deployed post-Batch08 functions;
- backward compatibility of existing callable contracts.

### Phase 3 — Core physical regression

Must include Google sign-in-first startup, existing profile recognition, Nearby, presence, text/media/voice messaging, Clear Chat, deletion semantics, Premium/recovery smoke, notifications, foreground/background, killed/reopen, Wi-Fi/mobile/weak-network behavior, logout/login and reboot/reopen.

Any unexplained failure stops promotion.

### Phase 4 — Stable-base promotion

Only after CI + signed artifact + physical regression + owner acceptance:

- documentation sync;
- GitHub recovery point;
- complete PC backup;
- SHA-256/checksum record;
- restore verification;
- stable-base promotion.

## Future feature sequence

Audio calling returns only after recovered stable-base acceptance and only as small sub-batches:

- 09A — call-session backend state;
- 09B — basic two-way Agora audio;
- 09C — incoming-call notification lifecycle;
- 09D — speaker/earpiece/proximity;
- 09E — Bluetooth;
- 09F — weak-network/reconnect;
- 09G — missed/cancelled/history/block/suspension edge cases.

Every sub-batch must pass its new behavior plus the mandatory core regression smoke before the next one begins.

## Later scope

- Batch 10 — video calling only after audio calling is stable and promoted.
- Owner/Admin Premium work remains paused until the consumer app is stable/release-ready.
- Final Play Store readiness includes production App Check/Play Integrity, full regression and release evidence.
