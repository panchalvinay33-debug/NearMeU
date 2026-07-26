# Current hardening batch

Branch: `fix/release-test-hardening-v1`

This branch is the guarded NearMeU V1 release-test and hardening branch. It preserves the stable app shell, unread handling, encrypted local chat storage, private photo/video/voice messaging, App Check enforcement and Firebase deployment work.

The official announcement system is now part of the project scope on this branch. It extends the existing text announcement flow with optional photo, video or voice attachments, app-update metadata, app-private local downloads, admin expiration and seven-day cloud-media retention with scheduled cleanup.

See:

- `V1_HARDENING_ROADMAP.md` for the ordered product and release roadmap.
- `PROJECT_BACKUP_ANNOUNCEMENTS.md` for the complete announcement feature recovery snapshot, storage policy, backend functions, deployment steps and physical-device acceptance tests.
