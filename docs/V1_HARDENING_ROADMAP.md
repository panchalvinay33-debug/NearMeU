# NearMeU V1 hardening roadmap

This roadmap keeps the current V1 scope stable while addressing production blockers in focused, reviewable pull requests.

## Batch 1 — Build gate and onboarding integrity

- [x] Store backend-compatible `Male` / `Female` preference values while keeping user-facing labels as Men / Women.
- [x] Add Flutter format, analyze, test, and debug-build checks in GitHub Actions.
- [x] Add Firestore emulator rule tests to the GitHub Actions quality gate.
- [x] Ignore Android signing keys, local properties, service-account credentials, and environment secrets.

## Batch 2 — Chat integrity

- [ ] Load the latest message window correctly and add older-message pagination.
- [ ] Restrict message updates to sender-only unsend, receiver-only seen updates, and owner-only delete-for-me changes.
- [ ] Deny client-side permanent message and chat deletion.
- [ ] Add Firestore emulator tests for every allowed and denied message mutation.

## Batch 3 — Presence and notifications

- [ ] Add app-lifecycle presence coordination.
- [ ] Register per-device FCM tokens in a private owner-only collection.
- [ ] Remove device tokens on logout and account deletion.
- [ ] Add trusted Cloud Functions for message push delivery.
- [ ] Add background notification handling and safe notification navigation.

## Batch 4 — Privacy architecture

- [ ] Split private account data from public nearby profile data.
- [ ] Keep exact coordinates, email, blocked users, settings, and device tokens private.
- [ ] Return only privacy-safe profile summaries and rounded distance to clients.
- [ ] Add migration for existing user documents.
- [ ] Update Privacy Policy and Data Safety declarations to match implementation.

## Batch 5 — Account deletion and moderation

- [ ] Reauthenticate before destructive cleanup.
- [ ] Move account deletion to an idempotent trusted backend workflow.
- [ ] Clean subcollections, tokens, storage, and private state safely.
- [ ] Preserve or anonymize shared safety records according to retention policy.
- [ ] Add immutable moderation audit entries and reviewer identity.

## Batch 6 — Release preparation

- [ ] Configure secure production upload signing.
- [ ] Add App Check and Play Integrity rollout.
- [ ] Complete public policy and account-deletion webpages.
- [ ] Run two-device, offline, background-push, block/report, deletion, and migration tests.
- [ ] Produce and verify the signed Android App Bundle.
