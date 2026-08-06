# NearMeU Ecosystem Boundary

Status: OFFICIAL GOVERNANCE
Last updated: 2026-08-06

## Purpose

NearMeU is one product ecosystem with two separate applications and repositories:

- Consumer app repository: `panchalvinay33-debug/NearMeU`
- Admin app repository: `panchalvinay33-debug/NearMeU-Admin`
- Consumer Android package: `com.nearmeu.nearmeu`
- Admin Android package: `com.nearmeu.admin`
- Shared Firebase project: `nearmeu-e82c7`

The two applications are related, but they are not one codebase and must not be merged into one Android application.

## Current development decision

Consumer NearMeU launch work is the active priority.

NearMeU Admin development is PAUSED until the owner explicitly resumes it after the consumer app launch path is complete. Existing Admin A01-A08 history remains reference material and must not be treated as accepted current consumer runtime.

## Code ownership

### Consumer-only code

Consumer UI/runtime belongs in `panchalvinay33-debug/NearMeU`, including:

- `lib/` consumer Flutter application code;
- consumer Android package/config;
- Nearby, Chats, messaging, profile sharing, Premium consumer UX, calling and launch/runtime work;
- consumer release/signing/recovery state.

### Admin-only code

Admin UI/runtime belongs in `panchalvinay33-debug/NearMeU-Admin`, including:

- Admin Flutter screens/navigation/models;
- Admin Android package `com.nearmeu.admin`;
- Admin-only signing/release/recovery artifacts;
- Admin operator documentation;
- Admin A01-A08 and future Admin UI phases.

### Shared backend code

Authoritative Firebase shared-backend source is controlled from the consumer/shared-backend repository `panchalvinay33-debug/NearMeU` unless a future governance decision explicitly creates a dedicated backend repository.

Admin privileged backend changes must therefore follow this rule:

1. define/implement the Admin UI/client contract in `NearMeU-Admin`;
2. create a fresh shared-backend branch from the current accepted `NearMeU/main`;
3. add only the narrowly required trusted callable/index/rule change;
4. run consumer regression/CI and Admin contract tests;
5. merge the shared backend only after review and required acceptance;
6. deploy Firebase only from clean exact `NearMeU/main`;
7. record the companion Admin PR and backend PR together.

Never deploy shared Firebase backend from `NearMeU-Admin` or from an unmerged historical Admin branch in `NearMeU`.

## Historical Admin branches in NearMeU

The branches `admin/a01-*` through `admin/a08-*` in the consumer/shared-backend repository are historical Admin backend development references.

Current rule:

- preserve them while Admin is paused unless the owner explicitly approves archival/deletion;
- do not merge them directly into current `main`;
- do not deploy them directly;
- when Admin resumes, inspect the useful contract/tests/logic and rebuild the required backend change from the then-current accepted `main`;
- obsolete or conflicting implementation code may be discarded after its useful requirements/tests have been captured.

## Branch cleanup classification

When cleaning `NearMeU` branches:

KEEP permanently:
- `main`
- `stable/official-recoverable-base`

PRESERVE WHILE ADMIN IS PAUSED:
- `admin/a01-admin-session-backend`
- `admin/a02-users-premium-backend`
- `admin/a03-business-dashboard-backend`
- `admin/a04-reports-moderation-backend`
- `admin/a05-recovery-health-backend`
- `admin/a06-messaging-health-backend`
- `admin/a07-system-health-backend`
- `admin/a08-audit-read-backend`

TEMPORARY / DELETE AFTER THEIR CLOSEOUT:
- stabilization branches;
- governance work branches;
- old batch/doc branches whose PR/commit history is already preserved;
- Batch09/calling experimental/checkpoint branches unless separately preserved by an explicit recovery decision.

Admin branches are not consumer runtime starting points, but they are also not generic clutter while the Admin project is paused.

## Security boundary

The Admin app must remain a privileged companion app, not a more powerful consumer client.

Required rules:

- private APK possession never grants Admin authority;
- every privileged action is server-authorized;
- role/permission claims fail closed;
- App Check is configured separately for consumer and Admin app registrations;
- Admin uses a separate permanent signing identity;
- destructive/admin mutations go through trusted server functions, not unrestricted client writes;
- least-privilege permissions are used per Admin feature;
- privileged reads/actions create audit evidence where appropriate;
- no unrestricted private-chat browser, exact-location browser, tokens/secrets or unnecessary private content exposure;
- consumer security rules must not be weakened merely to make Admin UI easier.

## Deployment ownership rule

Firebase project `nearmeu-e82c7` is shared infrastructure. A deployment can affect both applications.

Therefore every production deployment must answer before it runs:

- Is this consumer-only, shared-backend, or Admin-related?
- Which consumer and Admin contracts can be affected?
- Is the source the exact reviewed `NearMeU/main` SHA?
- Are any historical Admin functions being accidentally reintroduced?
- Does `tool/audit_production_state.ps1` show only functions exported by accepted source?

If these answers are not clear, deployment is blocked.

## Documentation synchronization rule

Whenever the project state, roadmap, deployment rules, recovery rules or branch-cleanup rules are reviewed/updated, this ecosystem relationship must also be checked.

At minimum these documents/tools must continue to agree:

- `docs/NEARMEEU_ECOSYSTEM_BOUNDARY.md`
- `docs/PROJECT_OPERATING_BLUEPRINT.md`
- `config/project_state_manifest.json`
- `tool/show_project_state.ps1`
- `tool/verify_deployment_gate.ps1`
- corresponding root governance documentation in `panchalvinay33-debug/NearMeU-Admin`

## Resume rule for Admin development

NearMeU Admin may resume only after explicit owner instruction. When it resumes:

1. read the current accepted NearMeU manifest/recovery state first;
2. read the current `NearMeU-Admin/main` state;
3. inventory A01-A08 feature status and deployed production drift;
4. treat old consumer-repo Admin branches as references, not merge bases;
5. choose a fresh Admin phase and its exact shared-backend contract;
6. test both apps against the same Firebase contract before production acceptance.
