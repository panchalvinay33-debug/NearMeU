# NearMeU Documentation Index

This is the current documentation map for the V1 launch line.

## Authoritative V1 documents

1. [`V1_LAUNCH_CHECKLIST.md`](V1_LAUNCH_CHECKLIST.md) — active launch gates and acceptance requirements.
2. [`MASTER_PROJECT_AUDIT.md`](MASTER_PROJECT_AUDIT.md) — current V1 project/backend truth and document precedence.
3. [`../config/project_state_manifest.json`](../config/project_state_manifest.json) — machine-readable current state.
4. [`WORKSPACE_AND_DEPLOYMENT_RULES.md`](WORKSPACE_AND_DEPLOYMENT_RULES.md) — authoritative PC workspace, recoverable-base, testing, backup and deployment rules.
5. [`EXECUTION_BATCH_PLAN.md`](EXECUTION_BATCH_PLAN.md) — despite the historical filename, this now contains the direct V1 launch execution plan and no numbered future batch roadmap.
6. [`TEST_BATCH_REGISTER.md`](TEST_BATCH_REGISTER.md) — despite the historical filename, this now contains the V1 launch verification register.
7. [`PRODUCT_DECISIONS.md`](PRODUCT_DECISIONS.md) — only product behavior required for the present V1 launch.
8. [`V2_AFTER_LAUNCH.md`](V2_AFTER_LAUNCH.md) — boundary for all non-launch work; no detailed V2 roadmap is active.
9. [`../README.md`](../README.md) — concise repository entry point.

## Current identifiers

- Launch branch: `v1/testing-baseline`
- Phase: `V1 LAUNCH STABILIZATION`
- Android package: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Active local project: `F:\NearMeU`
- Private recovery folder: `F:\NearMeU_Private_Backup`
- Final launch commit/artifact: freeze after launch checklist acceptance

## Current technical references

- [`../firestore.rules`](../firestore.rules) — Firestore client-access policy.
- [`../storage.rules`](../storage.rules) — Storage client-access policy.
- [`../firestore.indexes.json`](../firestore.indexes.json) — Firestore indexes.
- [`../functions/bootstrap.js`](../functions/bootstrap.js) — Firebase Functions entry point.
- [`ANDROID_PHONE_SMOKE_TEST.md`](ANDROID_PHONE_SMOKE_TEST.md) — phone smoke testing reference.
- [`PHYSICAL_ANDROID_TESTING.md`](PHYSICAL_ANDROID_TESTING.md) — physical Android testing reference.
- [`REALTIME_STABILITY_TEST_PLAN.md`](REALTIME_STABILITY_TEST_PLAN.md) — realtime/presence testing reference.
- [`PRODUCTION_RELEASE_RUNBOOK.md`](PRODUCTION_RELEASE_RUNBOOK.md) — release mechanics reference; the V1 checklist and workspace/deployment rules remain authoritative for what must be accepted and how production is changed.

## Current scope rule

Only launch-blocking defects and the four active V1 stability gates may drive pre-launch runtime work:

1. message delivery/read/unread truth;
2. identity deactivation/reactivation continuity;
3. `users` / `privateProfiles` consistency;
4. presence consistency across Nearby, Chats and Chat screen.

All other product work is deferred to V2 after V1 launch.

## Mandatory base/test/deploy discipline

Every meaningful runtime change follows:

`accepted base -> focused change -> automated tests -> physical tests -> merge/accept -> update F:\NearMeU -> controlled deployment if needed -> post-deploy verification -> new recoverable base`

Production deployment never happens merely because code was pushed or merged. Explicit Firebase target `nearmeu-e82c7`, relevant tests, backup for destructive/migrating work, and post-deploy verification are required. See [`WORKSPACE_AND_DEPLOYMENT_RULES.md`](WORKSPACE_AND_DEPLOYMENT_RULES.md).

## Document precedence

When documents disagree, use:

1. `V1_LAUNCH_CHECKLIST.md`
2. `MASTER_PROJECT_AUDIT.md`
3. `config/project_state_manifest.json`
4. `WORKSPACE_AND_DEPLOYMENT_RULES.md`
5. current `v1/testing-baseline` source/rules/functions
6. README and this index
7. topic-specific technical runbooks
8. old plans, old PR descriptions and historical commits

Historical records remain useful evidence, but they do not control the current launch scope.