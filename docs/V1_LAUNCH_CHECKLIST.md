# NearMeU V1 Launch Checklist

Last updated: 2026-08-08

This is the only active runtime checklist before the first public V1 launch. Work outside this checklist is not part of V1 launch stabilization.

## Current launch line

- Repository: `panchalvinay33-debug/NearMeU`
- Launch branch: `v1/testing-baseline`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Launch status: `STABILIZATION IN PROGRESS`
- Final launch commit and APK/AAB hash: freeze only after every required gate below passes.

## Already verified

- Firebase later-feature Firestore/Storage residue cleaned from the active backend.
- V1 Firestore rules, indexes and Storage rules deployed.
- V1 Cloud Functions deployed; later-feature Functions removed.
- Cloud Functions tests: 43 passed, 0 failed.
- Duplicate canonical chat audit: no duplicate chat pairs.
- Duplicate chat rows no longer reproduced in current physical test.
- Owner admin profile restored and verified.
- Google sign-in/session startup path restored for current testing.

## Open launch gates

### 1. Message delivery and read truth

Required behavior:

- sending/pending is distinct from server accepted;
- single tick = server accepted;
- grey double tick = receiver device synchronized/delivered;
- blue double tick = receiver opened/read;
- unread count agrees between chat list, chat screen and restart;
- test new messages on two accounts/devices, including foreground, background, offline/reconnect and restart.

Historical message fields are not rewritten merely to make old records look delivered/read. Acceptance is based on fresh test messages after the V1 backend alignment.

### 2. One account identity and deactivation/reactivation

Required behavior before launch:

- one signed-in Google/Firebase identity must not create duplicate NearMeU behavior;
- normal account exit is deactivation, not destructive identity deletion;
- deactivation preserves the same internal identity, existing profile and existing uncleared chats;
- deactivated users disappear from Nearby and cannot behave as currently active;
- existing counterpart chats show a neutral deactivated-account state instead of `Unavailable user` where the identity is intentionally deactivated;
- same account login/reactivation returns to the same profile and chats without onboarding;
- profile fields are not overwritten on reactivation; changes occur only through explicit profile editing;
- irreversible permanent deletion, if retained at all, must remain clearly separate from normal deactivation.

### 3. `users` and `privateProfiles` consistency

`users/{uid}` is the public profile. `privateProfiles/{uid}` is the private profile for email, exact location and private notification/settings data.

Before launch:

- classify current legacy users;
- migrate safely recoverable private fields out of old public documents;
- ensure valid active current-schema users have matching private profiles;
- identify malformed/empty legacy documents separately instead of inventing data;
- do not silently change nickname, age, gender or preference values unless a migration rule is explicit and safe;
- verify no private email/exact-location fields remain publicly exposed after successful migration.

### 4. Presence consistency

Nearby, Chats and the individual Chat screen must use the same presence truth.

Required behavior:

- online only while NearMeU is actually foreground/resumed;
- background, minimize, sign-out and normal app exit publish offline as soon as the platform lifecycle permits;
- stale presence must expire safely if a process/network failure prevents the offline write;
- the same `lastSeen` source is used everywhere;
- green dot appears only for effectively-online users;
- Nearby, Chats and Chat screen must not disagree about online/offline/last activity;
- physical tests must cover foreground, background, screen switching, restart, network loss and process termination.

## Final V1 launch acceptance

V1 is launch-ready only after:

1. all four open gates above pass;
2. Flutter/tests/Firebase tests required by the current source pass;
3. a clean signed release candidate is built;
4. physical Android smoke and two-account messaging tests pass;
5. Firebase production configuration matches the accepted V1 source;
6. final commit and artifact hashes are recorded;
7. owner explicitly accepts the release candidate.

## Scope lock

Until V1 launches, only work required to close the launch gates or fix a launch-blocking defect is allowed. No unrelated feature expansion is part of this launch line.

Anything not required for this V1 launch is recorded only as `V2 AFTER V1 LAUNCH` and will be planned after V1 is released.