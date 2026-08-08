# NearMeU Master Project Audit

Last updated: 2026-08-08

This is the authoritative human-readable state for the current NearMeU launch line. The project is not following an intermediate batch roadmap. The only current objective is to make the present V1 coherent, stable and launch-ready.

## 1. Authoritative current state

| Item | Current value |
|---|---|
| Repository | `panchalvinay33-debug/NearMeU` |
| Active launch branch | `v1/testing-baseline` |
| Phase | `V1 LAUNCH STABILIZATION` |
| Android application ID | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| Final launch commit | Not frozen yet |
| Final launch APK/AAB hash | Not frozen yet |
| Work not required for V1 launch | `V2 AFTER V1 LAUNCH` |

The final launch SHA and release artifact are frozen only after the active V1 launch checklist passes.

## 2. Backend alignment completed on 2026-08-08

The current Firebase backend was brought back into alignment with the V1 source before continuing launch stabilization.

Verified work:

- later-feature Firestore collections were backed up and removed from the active backend;
- later-feature recovery-media Storage objects were backed up and removed;
- V1 Firestore rules, indexes and Storage rules were deployed;
- V1 Cloud Functions were deployed and later-feature Functions removed;
- Cloud Functions tests passed: 43 passed, 0 failed;
- owner admin profile was restored and verified;
- duplicate chat audit returned no duplicate chat pairs;
- current physical testing no longer reproduced duplicate chat rows.

The active backend collections after cleanup are limited to the V1 data families currently in use, including `users`, `privateProfiles`, `chats`, `antiAbuseUsers`, `deviceTokenOwners`, `supportAnnouncements` and `adminAudit`.

## 3. Current architecture facts

### Public and private profiles

- `users/{uid}` contains the public/discovery profile.
- `privateProfiles/{uid}` contains private profile data such as email, exact location and private notification/settings data.
- Legacy users created before this split may still need a safe migration.

### Chat

- private chats use canonical participant-pair chat IDs;
- text/message metadata is stored in Firestore;
- private chat media uses Firebase Storage;
- V1 includes delivery acknowledgement, read acknowledgement and message-retention infrastructure;
- historical message records are not rewritten merely to make old receipt fields appear complete.

### Presence

- presence is tied to Flutter application lifecycle;
- foreground/resumed is the intended online state;
- background/non-resumed is intended offline state;
- heartbeat/freshness protection prevents stale `isOnline` from remaining authoritative indefinitely;
- all user-facing screens must converge on the same effective presence calculation before launch.

## 4. Open V1 launch gates

The exact checklist is [`V1_LAUNCH_CHECKLIST.md`](V1_LAUNCH_CHECKLIST.md). There are four active behavior groups:

1. **Delivery/read/unread truth** — verify fresh two-account/two-device messages and tick semantics.
2. **Identity continuity through deactivation/reactivation** — normal account deactivation must preserve the same identity/profile/chats and reactivate without duplicate-account behavior or onboarding.
3. **`users` / `privateProfiles` consistency** — classify and safely migrate legacy profiles without inventing or silently changing user data.
4. **Presence consistency** — Nearby, Chats and Chat screen must show the same online/offline/last-seen/green-dot truth, with online limited to the foreground app state.

No unrelated runtime feature is part of the current launch line.

## 5. Launch acceptance gate

V1 becomes launch-ready only when:

- all four behavior groups above pass;
- repository automated tests required by the launch source pass;
- Firebase rules/functions tests pass;
- a signed release candidate is built;
- physical Android smoke tests pass;
- two-account messaging/presence scenarios pass;
- Firebase deployed state matches the accepted source;
- final commit and artifact hashes are recorded;
- owner explicitly accepts the release candidate.

## 6. Recovery and safety rules

For any launch-blocking runtime change:

1. start from the current V1 launch line;
2. make one focused change;
3. run relevant automated/Firebase tests;
4. build/install a test APK when runtime behavior changes;
5. physically verify the exact affected behavior;
6. record the accepted commit/artifact only after acceptance.

Do not commit keystores, passwords, App Check debug tokens, service-account private keys, test credentials or live Firebase data.

## 7. Document precedence

For the active V1 launch, use this order:

1. `docs/V1_LAUNCH_CHECKLIST.md`
2. `docs/MASTER_PROJECT_AUDIT.md`
3. `config/project_state_manifest.json`
4. current `v1/testing-baseline` source/rules/functions
5. `README.md` and `docs/INDEX.md`
6. topic-specific technical runbooks
7. old batch plans, historical PRs, commits and archived planning records

Historical Git records remain history; they are not instructions for the current launch line.

## 8. After V1 launch

Anything that is not necessary to complete this V1 launch is deferred to **V2 AFTER V1 LAUNCH**. No detailed V2 roadmap is authoritative now. V2 will be planned fresh after V1 is released.