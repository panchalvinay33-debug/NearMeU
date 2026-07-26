# NearMeU V1 hardening roadmap

This roadmap keeps the current V1 scope stable while addressing production blockers in focused, reviewable pull requests.

## Batch 1 — Build gate and onboarding integrity

- [x] Store backend-compatible `Male` / `Female` preference values while keeping user-facing labels as Men / Women.
- [x] Add Flutter format, analyze, test, and debug-build checks in GitHub Actions.
- [x] Add Firestore emulator rule tests to the GitHub Actions quality gate.
- [x] Ignore Android signing keys, local properties, service-account credentials, and environment secrets.

## Batch 2 — Chat integrity

- [x] Load the latest message window correctly and retain local chat history safely.
- [x] Restrict message updates to trusted unsend, seen, unread and delete-for-me workflows.
- [x] Deny client-side permanent message and chat deletion.
- [x] Add Firestore emulator tests for allowed and denied message mutations.
- [x] Add private photo, video and voice messages with app-private local storage.
- [x] Add controlled cloud-media cleanup and download acknowledgement.

## Batch 3 — Presence and notifications

- [ ] Add app-lifecycle presence coordination.
- [ ] Register per-device FCM tokens in a private owner-only collection.
- [ ] Remove device tokens on logout and account deletion.
- [ ] Add trusted Cloud Functions for message push delivery.
- [ ] Add background notification handling and safe notification navigation.

## Batch 4 — Privacy architecture

- [x] Split sensitive chat media from public app storage and keep downloaded media inside app-private storage.
- [ ] Split private account data from public nearby profile data completely.
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

## Batch 6 — Official announcements and app updates

This is now part of the official NearMeU product scope, not an experimental add-on.

- [x] Preserve the existing text-only support announcement flow.
- [x] Add announcement categories: General, New Feature, App Update, Maintenance and Important.
- [x] Add one optional attachment per announcement: photo, video or voice.
- [x] Add admin-side media selection, voice recording, preview and upload flow.
- [x] Add user-side photo viewing, video playback and voice playback.
- [x] Store downloaded announcement media in app-private mobile storage, not Gallery or Downloads.
- [x] Add app version, update URL, custom update-button label and mandatory-update metadata.
- [x] Keep announcement media available in cloud storage for seven days.
- [x] Run scheduled cleanup every six hours for media whose seven-day retention has expired.
- [x] Delete announcement media immediately when an admin expires the announcement.
- [x] Keep all new announcement fields optional so legacy text announcements remain compatible.
- [ ] Add push notification delivery when a new official announcement is published.
- [ ] Add analytics for delivered, opened, media-played and update-button-clicked events.
- [ ] Add production Play Store update enforcement after release signing and store publication are ready.

## Batch 7 — Release preparation

- [ ] Configure secure production upload signing.
- [x] Add App Check enforcement and debug-provider testing support.
- [ ] Complete public policy and account-deletion webpages.
- [ ] Run two-device, offline, background-push, block/report, deletion, migration and announcement-media tests.
- [ ] Produce and verify the signed Android App Bundle.
