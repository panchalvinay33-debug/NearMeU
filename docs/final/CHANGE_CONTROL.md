# NearMeU — Change Control

This policy prevents future work from damaging the verified permanent-signed baseline.

## Protected baseline

The recovery baseline is commit `48a290c58a14a71174b921832e516b568b06ba48` and branch `stable/permanent-signed-2026-07-30`.

## Required workflow for every change

1. Update local `main` from GitHub.
2. Create one focused branch: `feature/...`, `fix/...`, `security/...`, `docs/...` or `ops/...`.
3. Make the smallest change that solves one clearly documented problem.
4. Never include credentials, user exports, keystores or passwords.
5. Open a PR to `main`.
6. Require green Flutter, Functions and Firebase Rules checks.
7. Review changed files and confirm no unrelated deletions or generated files.
8. For runtime changes, test on a physical Android phone.
9. For auth/signing/App Check changes, verify package, SHA fingerprints and provider behavior.
10. Merge only after checks and acceptance criteria pass.
11. Delete temporary work branches only after the merged result is proven stable.
12. Record a new stable recovery point before retiring the previous one.

## Changes that require extra approval/testing

- Android package/application ID
- Signing key or key password migration
- Firebase project or Android app registration
- Authentication providers or OAuth clients
- App Check provider or enforcement
- Firestore/Storage rules
- Cloud Functions that delete, moderate or retain data
- Database schema or retention behavior
- Account deletion
- Forced-update logic
- Permissions, location behavior or privacy controls

## Release acceptance gate

A release candidate is acceptable only when:

- CI is green.
- Permanent signing certificate is verified.
- Debug or Play-track installation succeeds as appropriate.
- Login, Nearby, profile, chat and logout/re-login pass.
- App Check works for the selected build type.
- Backend deployment version is recorded.
- Backup exists before data/rules migration.
- Rollback target is known.

## Prohibited shortcuts

- Direct experimental commits to `main`
- Force-pushing or deleting `main`
- Replacing the permanent signing key casually
- Publishing artifacts from an unknown local keystore
- Enabling App Check enforcement before release-provider testing
- Assuming CI means Firebase has been deployed
- Deleting stable branches before a replacement recovery point is verified
- Sharing secret values in chat, issues, screenshots or commit history

## Documentation rule

Every material change must update at least one of:

- `docs/final/CURRENT_VERIFIED_STATE.md`
- `docs/final/ROADMAP_AND_RELEASE_PLAN.md`
- `docs/final/RECOVERY_PLAYBOOK.md`
- `config/project_state_manifest.json`

The repository must always answer four questions without external memory:

1. What is working now?
2. What remains?
3. How is it built and secured?
4. How do we recover the last known-good app?
