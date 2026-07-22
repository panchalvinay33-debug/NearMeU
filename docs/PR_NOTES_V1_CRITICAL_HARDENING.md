# V1 critical hardening — batch 1

## What changed

- Fixed onboarding preference persistence so the UI can display Men / Women while Firestore receives the schema-compatible values Male / Female.
- Added a GitHub Actions quality gate for formatting, static analysis, Flutter tests, debug APK compilation, and Firestore emulator rule tests.
- Hardened `.gitignore` for Android signing keys, local properties, Firebase Admin credentials, service-account files, and environment secrets.
- Added a staged V1 hardening roadmap covering chat rules, presence, notifications, privacy architecture, account deletion, moderation, and release preparation.

## Why

The current app could reject new profiles because the onboarding screen saved `Men` / `Women`, while validation and Firestore rules accept `Male` / `Female`. The repository also had no automated checks on pull requests and did not explicitly ignore release-signing and backend credential files.

## User impact

- New users selecting Men or Women can save a valid profile.
- Future pull requests receive repeatable automated feedback before merge.
- Sensitive release and backend files are less likely to be committed accidentally.

## Validation

The branch was created directly from the latest `main` commit. GitHub Actions will perform the Flutter and Firestore emulator checks when the pull request opens. Local Flutter execution was unavailable in the current workspace, so merge must remain blocked until CI results are reviewed.
