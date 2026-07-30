# NearMeU — Change Control

This policy prevents future work from damaging the verified permanent-signed baseline.

## Protected baseline

- Default branch: `main`
- Official recovery branch: `stable/official-base-v1-2026-07-30`
- Base merge commit: `a743ffa407c145b3852c547d31f33458e8e839b4`

## Required workflow for every change

1. Update local `main` from GitHub.
2. Create one focused branch: `feature/...`, `fix/...`, `security/...`, `docs/...` or `ops/...`.
3. Make the smallest change that solves one documented problem.
4. Never commit credentials, user exports, keystores, passwords or debug tokens.
5. Open a pull request to `main`.
6. Require these checks to pass: `Flutter checks`, `Firebase rules tests`, `Cloud Functions checks`.
7. Review changed files and confirm there are no unrelated deletions or generated files.
8. Test runtime changes on a physical Android phone.
9. For auth/signing/App Check changes, verify package, SHA fingerprints and provider behavior.
10. Merge only after checks and acceptance criteria pass.
11. Delete the temporary work branch after the merged result is proven stable.
12. Record a new official recovery point before replacing the current one.

## Main branch protection

The active ruleset for `main` requires pull requests and the three required checks, restricts deletion, and blocks force pushes. Direct writes to `main` must remain prohibited.

## Changes requiring extra testing

- Android package/application ID
- signing key or password migration
- Firebase project or Android app registration
- Authentication providers or OAuth clients
- App Check provider or enforcement
- Firestore/Storage rules
- Cloud Functions that delete, moderate or retain data
- database schema or retention behavior
- account deletion
- forced-update logic
- permissions, location behavior or privacy controls

## Release acceptance gate

A release candidate is acceptable only when CI is green, the permanent certificate is verified, installation succeeds, login/Nearby/profile/chat pass, App Check works for the build type, backend deployment is recorded, and backup/rollback targets are known.

## Prohibited shortcuts

- Direct experimental commits to `main`
- Force-pushing or deleting `main`
- Replacing the permanent signing key casually
- Publishing artifacts from an unknown local keystore
- Enabling App Check enforcement before release-provider testing
- Assuming CI means Firebase has been deployed
- Deleting the official recovery branch before a replacement is verified
- Sharing secret values in chat, issues, screenshots or commit history

## Documentation rule

Every material change must update at least one of:

- `docs/final/CURRENT_VERIFIED_STATE.md`
- `docs/final/ROADMAP_AND_RELEASE_PLAN.md`
- `docs/final/RECOVERY_PLAYBOOK.md`
- `docs/final/OFFICIAL_BASE_MARKER.md`
- `config/project_state_manifest.json`

The repository must always answer: what works now, what remains, how it is built and secured, and how to recover the last known-good app without relying on chat history.