# NearMeU — Roadmap and Release Plan

## Phase 0 — Baseline freeze

Status: **Complete in source control**

- Freeze the non-calling product scope.
- Preserve the verified APK commit and CI run references.
- Record current architecture, security boundaries and deferred items.
- Store the machine-readable project manifest in the repository.

## Phase 1 — Production Firebase preparation

Status: **Operational work required**

- Confirm the correct production Firebase project ID.
- Confirm Blaze billing is enabled and budget alerts are configured.
- Deploy Firestore rules, indexes and Storage rules.
- Deploy Cloud Functions, including private-chat and support-announcement notifications.
- Verify required service accounts and least-privilege IAM.
- Enable App Check enforcement only after release App Check testing succeeds.

Acceptance criteria:

- Emulator tests remain green.
- Production rules deny unauthorized reads/writes.
- Announcement and private-chat pushes work on two real accounts.
- Invalid FCM tokens are cleaned up.

## Phase 2 — Device acceptance testing

Status: **Required before Play Store**

Test with at least two physical Android devices and separate accounts:

1. Signup, login, logout and re-login.
2. Profile creation and editing.
3. Nearby refresh, search and distance filters.
4. Offline/cached Nearby behavior.
5. Text, image, video and voice-note chat.
6. Foreground, background and terminated push notifications.
7. Notification tap routing.
8. Block/unblock and report behavior.
9. Suspended-user access denial.
10. Message deletion/unsend and private media behavior.
11. Account deletion and reauthentication.
12. Forced-update gate.
13. Screenshot protection behavior.
14. Reinstall and token re-registration.

Acceptance criteria:

- No crash or data leakage.
- No unauthorized chat/media access.
- No broken navigation loops.
- Failed uploads and weak-network states are understandable.

## Phase 3 — Play Store release preparation

Status: **Required before publishing**

- Create and securely back up the Android upload key.
- Configure release signing outside source control.
- Build signed `.aab`.
- Finalize app icon, feature graphic, phone screenshots and store descriptions.
- Publish Privacy Policy and account-deletion information on stable public URLs.
- Complete Data Safety, content rating, target audience and app-access declarations.
- Create Closed Testing release.

Acceptance criteria:

- Signed bundle installs through Play testing track.
- Play Integrity and release App Check succeed.
- No secrets or signing files are committed to Git.

## Phase 4 — Closed testing

Status: **Required before production**

- Start with 20–50 trusted testers.
- Monitor Crashlytics, support feedback, failed function calls and database cost.
- Fix only launch-blocking defects; avoid adding major new features.
- Repeat smoke test after every release candidate.

Suggested exit criteria:

- No unresolved critical/high-severity issue.
- Stable login, discovery, chat and notification flows.
- Account deletion verified.
- Cloud usage remains within planned budget.

## Phase 5 — Production launch

Status: **Future operational action**

- Roll out gradually where Play Console permits.
- Watch crashes, ANRs, authentication failures, notification failures and cost alerts.
- Keep the previous stable Play release available for rollback.
- Use forced update only for security or incompatible-data changes.

## Post-launch roadmap

### Priority A — Reliability

- Improve retry queues and media upload telemetry.
- Add operational dashboards and automated backup verification.
- Tune Firestore queries and indexes using production metrics.

### Priority B — User experience

- Continue screen-by-screen polish based on tester recordings and screenshots.
- Improve accessibility and localization readiness.
- Refine trust/safety education and reporting feedback.

### Priority C — Scale

- Media lifecycle and egress optimization.
- Cost controls and rate limits.
- More robust announcement audience segmentation.

### Deferred product expansion

- Voice/video calling
- Paid plans
- iOS app

These require a separate architecture, cost and privacy review and must not be mixed into the current launch baseline.
