# NearMeU V1 Launch Execution Plan

Last updated: 2026-08-08

NearMeU is no longer using a numbered pre-launch batch roadmap. The execution model is intentionally simple:

**Current V1 -> close launch blockers -> verify release candidate -> launch -> observe/stabilize production -> plan V2 fresh.**

Everything not required for this V1 launch is deferred to `V2 AFTER V1 LAUNCH`.

## Current source

- Active launch branch: `v1/testing-baseline`
- Active local project: `F:\NearMeU`
- Private recovery folder: `F:\NearMeU_Private_Backup`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Final launch commit: freeze only after launch acceptance

## Phase A — finish V1 launch stabilization

The only allowed pre-launch runtime work is defined in [`V1_LAUNCH_CHECKLIST.md`](V1_LAUNCH_CHECKLIST.md):

1. message delivery/read/unread truth;
2. one-account identity with deactivation/reactivation continuity;
3. `users` / `privateProfiles` consistency and safe legacy migration;
4. presence consistency across Nearby, Chats and Chat screen.

A defect discovered during testing may also be fixed before launch when it is genuinely launch-blocking and directly affects current V1 behavior.

The intent is not to perfect every possible feature. The intent is to make the current product stable, understandable and safe enough to launch without reopening old 8.1/Batch09 expansion work.

## Phase B — release candidate and launch

When all four V1 gates pass:

1. freeze the exact accepted commit;
2. verify the local `F:\NearMeU` working tree is clean and on that commit;
3. verify automated tests/CI;
4. ensure Firebase production configuration matches the accepted source;
5. build the permanently signed release candidate;
6. run physical Android smoke and two-account tests on that release candidate;
7. record final APK/AAB checksum and accepted commit SHA;
8. copy final recovery evidence/artifact checksum into `F:\NearMeU_Private_Backup`;
9. owner explicitly accepts the release candidate;
10. launch V1.

## Phase C — immediate post-launch period

After launch, do not immediately begin large feature expansion.

First:

- watch real production behavior;
- fix only genuine launch regressions, crashes, auth/backend breakage, messaging/presence defects or security/privacy issues;
- keep fixes small and isolated;
- use the same base -> test -> physical verification -> controlled deploy -> post-deploy verification rule;
- keep the accepted V1 launch commit as the recovery anchor.

## Phase D — start V2 deliberately

Only after V1 has launched and the initial production state is understood:

- review user feedback and actual production problems;
- decide which larger features are worth building;
- create a fresh V2 plan from the accepted V1 production base;
- old 8.1/Batch08/Batch09 branches may be consulted as reference, but are not automatically revived or merged;
- each V2 feature is re-evaluated against the current product architecture and Firebase data before implementation.

V2 should grow from the launched V1 rather than replacing it with an old advanced snapshot.

## Per-change execution rule

For every runtime fix or later V2 feature:

1. work from the current accepted base;
2. isolate one problem/change;
3. make the smallest necessary coherent change;
4. run relevant Flutter/Firebase/Functions tests;
5. build an installable APK when runtime behavior changes;
6. physically test the affected scenario;
7. use two accounts/devices when behavior crosses users;
8. verify app restart/background/offline behavior where applicable;
9. merge only after acceptance;
10. update `F:\NearMeU` to the accepted merged commit;
11. deploy only the required backend components when a deployment is needed;
12. run post-deploy smoke/audit;
13. record the accepted commit/test result and refresh recovery evidence when it becomes a new meaningful base.

The detailed workspace, backup and deployment requirements are authoritative in [`WORKSPACE_AND_DEPLOYMENT_RULES.md`](WORKSPACE_AND_DEPLOYMENT_RULES.md).

## Final V1 release-candidate gate

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

There is no active detailed V2 feature sequence before V1 launch. V2 planning begins after launch from the accepted V1 production base. Old future-feature sequences are historical reference only and must not drive current work automatically.