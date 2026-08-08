# NearMeU V1 Launch Execution Plan

Last updated: 2026-08-08

NearMeU is no longer using a numbered pre-launch batch roadmap. The execution model is now intentionally simple:

**Current V1 -> close launch blockers -> verify release candidate -> launch.**

Everything not required for this V1 launch is deferred to `V2 AFTER V1 LAUNCH`.

## Current source

- Active launch branch: `v1/testing-baseline`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Final launch commit: freeze only after launch acceptance

## Active work only

The only allowed pre-launch runtime work is defined in [`V1_LAUNCH_CHECKLIST.md`](V1_LAUNCH_CHECKLIST.md):

1. message delivery/read/unread truth;
2. one-account identity with deactivation/reactivation continuity;
3. `users` / `privateProfiles` consistency and safe legacy migration;
4. presence consistency across Nearby, Chats and Chat screen.

A defect discovered during testing may also be fixed before launch when it is genuinely launch-blocking and directly affects the current V1 behavior.

## Per-change execution rule

For every runtime fix:

1. work from the current V1 launch line;
2. isolate one problem and make the smallest necessary change;
3. do not add unrelated functionality;
4. run the relevant Flutter/Firebase/Functions tests;
5. build an installable APK when runtime behavior changes;
6. physically test the affected scenario;
7. use two accounts/devices when behavior crosses users;
8. verify app restart/background/offline behavior where applicable;
9. update the launch checklist/audit with the result;
10. accept the change only after owner verification.

## Final release-candidate gate

Before launch:

- all launch-checklist gates pass;
- no duplicate chat behavior reproduces;
- admin access remains correct;
- Firebase deployed rules/indexes/functions/storage configuration matches the accepted source;
- auth startup/session persistence works;
- fresh delivery/read receipts work;
- deactivation/reactivation identity works;
- profile/public-private migration is consistent;
- presence truth is consistent on all three user-facing surfaces;
- signed release candidate builds and installs;
- final commit and artifact hashes are recorded.

## V2 boundary

There is no active detailed post-launch roadmap in this document. New features and larger redesigns will be reconsidered and planned fresh as V2 after V1 has launched. Old numbered future sequences are historical only and must not drive current work.