# NearMeU — Current Final Baseline

**Baseline date:** 2026-07-27  
**Repository:** `panchalvinay33-debug/NearMeU`  
**Branch:** `fix/release-test-hardening-v1`  
**Verified APK commit:** `fe417dd38d06e010d4c521813d0f0959a931b5b4`  
**Product decision:** Calling is postponed. This baseline is the complete non-calling NearMeU app.

## Product scope frozen in this baseline

NearMeU is a nearby people discovery and private messaging app with:

- Google/Firebase authentication and profile onboarding
- Nearby discovery using saved/current location
- Search and distance filtering
- Public profile viewing
- Private one-to-one chat
- Text, photo, video and voice-note messaging
- Private media access controls and local-first media handling
- Message unread counts and chat previews
- Block, report, suspension and account deletion flows
- In-app notifications and FCM push notifications
- Official support announcements with rich media support
- Forced update gate
- App Check with Play Integrity in release mode
- Screenshot protection/privacy guard
- Crash/error observability and startup tracing
- Admin dashboard and moderation capabilities
- Privacy Policy, Terms, Community Guidelines, About and Help screens

## Current UI/UX baseline

- Centralized Material 3 dark design system
- Consistent buttons, inputs, cards, dialogs, snackbars and navigation
- Polished notification settings
- Responsive Nearby header and profile cards
- Loading, empty, error and offline states
- Accessibility labels and safer large-text behavior
- Cached Nearby fallback when the network is unavailable

## Notification baseline

### Private chat

- FCM token registration, refresh and logout cleanup
- Foreground local notification display
- Background/terminated notification opening
- Safe navigation to authorized chat only
- Duplicate route suppression
- Privacy-safe message preview

### Official announcements

- Firestore create trigger for active all-user announcements
- Active, non-suspended user filtering
- Batched multicast delivery
- Invalid token cleanup
- Tap navigation to Support Announcements

The announcement Cloud Function must be deployed to the production Firebase project before production push delivery is considered live.

## Security baseline

- Firebase App Check
- Play Integrity for release builds
- Firestore and Storage security rules tests
- Private chat membership checks
- Block and suspension enforcement
- Screenshot/capture guard
- Forced minimum-version gate
- Signed release enforcement; unsigned release builds are intentionally rejected

## Build verification

GitHub Actions quality gate verifies:

- Dart formatting
- Flutter static analysis
- Flutter tests
- Debug APK build
- Cloud Functions unit tests
- Secure function loading
- Firebase emulator rules tests
- Unsigned release rejection

The debug APK generated from the verified baseline is for device testing only, not Play Store publication.

## Production completion boundary

The code baseline is complete for the current non-calling scope. Production launch still requires operational actions outside source coding:

1. Deploy Firebase Functions and rules to the intended production project.
2. Configure production App Check and Play Integrity.
3. Create and protect Android upload/release keys.
4. Build a signed Android App Bundle (`.aab`).
5. Complete two-device testing for chat, media, notifications, blocking and account deletion.
6. Verify public legal-policy URLs and Play Console data-safety answers.
7. Configure cloud billing budgets and alerts.
8. Enable and verify scheduled database/storage backups.
9. Run Closed Testing before public production release.

## Deferred work

- Voice/video calling
- Paid subscriptions or in-app purchases
- Large-scale video delivery optimization/CDN work
- iOS release

Deferred items are not blockers for the current Android non-calling launch.
