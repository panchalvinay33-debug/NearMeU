# NearMeU Workspace and Deployment Rules

Last updated: 2026-08-08

This document is authoritative for how NearMeU source, local PC copies, testing, backups and production deployment are handled from the current V1 launch line onward.

## 1. PC workspace rule

The normal working source folder is:

- `F:\NearMeU` — the only active NearMeU Git working copy.

Private/non-Git recovery material is kept separately:

- `F:\NearMeU_Private_Backup` — private backups, Firebase audit exports, migration backups, service-account material, old recovery ZIPs and later the accepted release artifact/checksum.

Temporary audit tooling may remain during launch verification:

- `F:\NearMeU_Firebase_Audit` — temporary audit/tooling folder only; remove after final V1 verification when its required evidence has been copied into `NearMeU_Private_Backup`.

Old development/recovery working copies must not become active project sources. Once the current `F:\NearMeU` clone and private backup are verified, old folders such as `NearMeU_V1_Deploy`, `NearMeU_V1_ProfileFix`, `NearMeU_Recovery08`, `NearMeU-OLD` and `NearMeU_OLD_ADVANCED_BACKUP` may be removed.

Secrets must never be stored inside `F:\NearMeU` or committed to GitHub.

## 2. One-source rule

- GitHub repository: `panchalvinay33-debug/NearMeU`
- Active V1 launch branch: `v1/testing-baseline`
- Local active project: `F:\NearMeU`
- Firebase project: `nearmeu-e82c7`

No old ZIP, old branch, old PC folder or historical batch becomes authoritative merely because it contains newer or more features.

## 3. Per-change rule

Every runtime change follows the same sequence:

1. start from the current accepted V1 base;
2. create/isolate a focused branch or focused change;
3. change only the required behavior;
4. run relevant Flutter, Functions and Firebase/rules tests;
5. build an installable APK when runtime behavior changes;
6. physically test the affected behavior;
7. use two accounts/devices for cross-user behavior;
8. verify background/restart/offline behavior when relevant;
9. merge only after the change is accepted;
10. update `F:\NearMeU` to the merged accepted commit;
11. record the accepted commit/test result in project documents;
12. take/refresh the PC recovery copy or release evidence when the change establishes a new recoverable base.

A code change is not an accepted base merely because CI passes. Physical behavior and source/backend compatibility must also be verified when applicable.

## 4. Recoverable-base rule

After a meaningful stable milestone, especially after a launch gate closes or before/after a production deployment:

- Git working tree must be clean;
- accepted commit SHA must be known;
- CI/tests required for that change must pass;
- physical test evidence must be recorded when required;
- Firebase deployed state must match the accepted source when backend configuration changed;
- important private backup/audit evidence must exist outside Git in `F:\NearMeU_Private_Backup`;
- `F:\NearMeU` must be updated to the accepted commit.

Do not create multiple competing active project folders for each milestone. Git commit/branch history is the source backup; private evidence goes in `NearMeU_Private_Backup`.

## 5. Deployment rule

Production deployment is never automatic just because code is committed or a PR is merged.

Deploy only when all of the following are true:

1. the exact accepted source commit is identified;
2. the affected automated tests pass;
3. the relevant physical test passes when runtime behavior is involved;
4. a backup is taken before destructive/migrating backend operations;
5. Firebase target is explicitly `nearmeu-e82c7`;
6. only the Firebase components required by the accepted change are deployed;
7. deployed Functions/rules/indexes/storage configuration is verified after deployment;
8. a post-deploy smoke/audit is run;
9. the result is recorded before calling the state a new stable base.

Use explicit project targeting rather than relying on the historical `.firebaserc` default alias:

`--project nearmeu-e82c7`

Do not run broad destructive cleanup commands, dependency auto-fixes, force resets, migrations or Function deletions without first verifying the exact target and taking the required backup.

## 6. V1 launch deployment

For the final V1 release candidate:

- all launch gates in `V1_LAUNCH_CHECKLIST.md` must pass;
- the accepted launch commit is frozen;
- Firebase production must match that exact accepted source;
- a permanently signed release APK/AAB is built from that commit;
- physical smoke/two-account tests pass on the release candidate;
- final artifact SHA-256 is recorded;
- a copy of the accepted artifact/checksum is stored in `F:\NearMeU_Private_Backup`;
- owner explicitly accepts the release candidate before public launch.

## 7. After V1 launch

V1 becomes the production/recovery base. Post-launch development begins as V2 from the accepted V1 launch commit, not from old Batch08/09/8.1 branches or old PC folders.

For V2, use the same discipline:

`stable production base -> focused change -> automated tests -> physical tests -> accepted commit -> controlled deployment -> post-deploy verification -> next base`

V2 features and their order will be planned only after V1 has launched. Historical future-feature branches are reference material, not an automatic roadmap.