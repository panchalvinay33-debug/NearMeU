# NearMeU V1 hardening plan

This branch is the release-hardening line created from the latest `main`. New product features remain out of scope until the production blockers below are completed and verified.

## Completed in this slice

- [x] Store canonical `Male` / `Female` preference values while keeping friendly Men / Women labels.
- [x] Stop treating legacy profiles with a missing age as automatically adult.
- [x] Require mutual gender/preference compatibility in Nearby eligibility.
- [x] Add tests for missing-age exclusion, legacy label normalization, mutual compatibility, blocking, distance, and ordering.
- [x] Replace debug release signing with mandatory private upload-key configuration.
- [x] Ignore keystores, signing properties, service accounts, and local Firebase credentials.
- [x] Add GitHub Actions gates for formatting, analysis, Flutter tests, debug build, and Firestore emulator tests.
- [x] Replace the default Flutter README with NearMeU setup and release documentation.

## Remaining release blockers

- [ ] Split private user data from the public Nearby profile; exact coordinates, email, blocked users, and device tokens must not be readable by other users.
- [ ] Move nearby-distance calculation to a trusted backend or privacy-preserving geo-query model.
- [ ] Restrict message updates to sender-only unsend, receiver-only seen state, and owner-only delete-for-me operations.
- [ ] Load the latest chat page and add older-message pagination.
- [ ] Implement lifecycle-safe presence with reliable offline handling.
- [ ] Register FCM tokens privately and send background notifications from Cloud Functions.
- [ ] Move account deletion to an authenticated, idempotent backend workflow that deletes subcollections and authentication data.
- [ ] Record Terms, Privacy Policy, and Community Guidelines acceptance with a version and server timestamp.
- [ ] Add immutable moderation audit events and verified report resolution metadata.
- [ ] Add App Check rollout, Crashlytics, staging deployment, and two-device release verification.

## Merge rule

Do not merge this branch until the GitHub Actions workflow is green and the changed onboarding/Nearby flows pass manual testing against a staging Firebase project.
