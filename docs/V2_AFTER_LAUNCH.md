# NearMeU V2 After V1 Launch

Last updated: 2026-08-08

There is intentionally no detailed V2 feature roadmap before V1 launches.

## Rule

- V1 work is limited to the current launch-stability checklist and genuine launch-blocking defects.
- Any product feature, expansion or redesign not required to make current V1 safe and stable is deferred.
- V2 planning starts only after V1 is publicly launched and its initial real-world behavior is reviewed.
- V2 starts from the accepted V1 production/recovery commit, not from old Batch08/8.1/Batch09 branches or old PC copies.
- Historical advanced branches may be consulted for ideas or reusable code, but every feature must be reconsidered against the launched architecture and current Firebase data before being reintroduced.

## Post-launch sequence

1. keep the accepted V1 launch commit as the production recovery anchor;
2. monitor/fix only genuine launch regressions first;
3. collect actual user feedback and production evidence;
4. decide V2 priorities fresh;
5. implement one focused V2 change at a time;
6. for every meaningful base: automated tests -> physical tests -> accepted commit -> update `F:\NearMeU` -> controlled deployment if required -> post-deploy verification -> recovery evidence;
7. continue keeping private backup material outside Git in `F:\NearMeU_Private_Backup`.

The authoritative pre-launch checklist is [`V1_LAUNCH_CHECKLIST.md`](V1_LAUNCH_CHECKLIST.md).

Workspace, base, backup and deployment discipline is defined in [`WORKSPACE_AND_DEPLOYMENT_RULES.md`](WORKSPACE_AND_DEPLOYMENT_RULES.md).