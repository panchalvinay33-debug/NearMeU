# NearMeU project backup — official announcements and app updates

Status: official product feature

Branch: `fix/release-test-hardening-v1`

This document is the recovery snapshot for the NearMeU official announcement system. It records the intended behavior, retention policy, architecture and validation requirements so the feature can be continued safely in a future development session.

## Existing system retained

- Firestore collection: `supportAnnouncements`
- Admin announcement composer and sent-history screen
- User-facing NearMeU Support announcement list
- Priority levels: normal, important and urgent
- Unread count and mark-all-read state
- Admin expire/hide action
- Legacy text-only announcement documents remain supported

## Added official capabilities

- Announcement categories: General, New Feature, App Update, Maintenance and Important
- One optional media attachment per announcement: image, video or voice
- Admin image/video picker
- Admin voice recording
- Upload progress and preview
- User image viewing
- User video playback
- User voice playback
- App version metadata
- Update URL for Play Store, controlled APK distribution or another approved update location
- Configurable update-button label
- Mandatory-update metadata

## Storage and privacy design

Cloud media path:

```text
announcementMedia/<announcement-id>/media.<extension>
```

Downloaded announcement media is stored inside NearMeU app-private mobile storage. It must not automatically appear in Gallery or Downloads.

Only authenticated users may read announcement media. Only an authenticated NearMeU admin may upload or delete it. Private-chat media rules and paths remain separate and must not be reused or weakened.

## Seven-day retention policy

- Cloud photo, video and voice attachments remain available for seven days from publication.
- Cleanup checks run every six hours.
- Expired cloud media is deleted and the announcement records its deletion state.
- Admin expiration removes the cloud attachment immediately.
- Media is not deleted when the first user downloads it because announcements are broadcasts for many users.
- A downloaded local copy may remain in app-private storage until app data is cleared, the app is uninstalled, or future local-cache cleanup removes it.
- Text, version and update-link metadata may remain useful after media expiry, depending on the announcement's active state.

## Main implementation files

```text
lib/models/support_announcement.dart
lib/services/announcement_service.dart
lib/services/announcement_media_service.dart
lib/screens/admin_announcement_screen.dart
lib/screens/support_announcements_screen.dart
lib/widgets/announcement_media_card.dart
functions/announcement_media_functions.js
functions/secure_entrypoint.js
firestore.rules
storage.rules
```

## Backend functions

- `expireSupportAnnouncement`: admin-only callable that expires an announcement and deletes its attachment.
- `purgeExpiredAnnouncementMedia`: scheduled cleanup that removes media after the seven-day retention period.

Global callable App Check enforcement remains enabled through the secure Functions entrypoint.

## Compatibility rule

All new announcement fields must stay optional when parsing Firestore documents. Existing text-only announcements must continue to load and display without migration.

## Deployment requirements

After pulling this feature to a test PC, validate and deploy with:

```powershell
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
flutter build apk --debug

cd functions
npm install
npm test
cd ..

$env:FUNCTIONS_DISCOVERY_TIMEOUT="120000"
firebase deploy --only functions,firestore:rules,storage
```

## Required physical-device tests

1. Existing text-only announcement still publishes and displays.
2. Image announcement uploads, downloads and opens.
3. Video announcement downloads and plays.
4. Voice announcement records, publishes and plays.
5. App Update announcement shows version, link and button label.
6. Mandatory-update metadata displays correctly without blocking unrelated existing screens prematurely.
7. Admin expire removes the announcement from the active list and deletes cloud media.
8. App navigation, Nearby, Chats, private photo/video/voice messages and unread badges remain unaffected.
9. Announcement media does not appear automatically in the phone Gallery.

## Planned follow-up work

- Push notifications for newly published announcements
- Delivery/open/play/update-click analytics
- Production Play Store update enforcement
- Optional local cache cleanup policy
- Multiple-media announcements only after the single-attachment version is proven stable
