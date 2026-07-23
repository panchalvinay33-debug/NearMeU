# NearMeU Google Play listing package

**Status:** Publication draft. Replace bracketed placeholders and verify all statements against the shipping build before submission.

## App name

NearMeU

## Short description

Discover compatible adults nearby and chat privately with safety controls.

## Full description

NearMeU is an adults-only social discovery app designed to help people find compatible users nearby and start private conversations.

### Discover nearby people

Use location-based discovery to view compatible adult profiles within a selected distance. NearMeU limits public location precision and keeps exact location details private.

### Private one-to-one chat

Start private conversations, reply to messages, see read status, unsend your own messages and remove messages from your own view.

### Safety and privacy controls

- Block users in either direction
- Report inappropriate behaviour
- Message and report rate limits to reduce spam
- Account suspension support
- Secure account deletion flow
- Privacy-focused push notifications without private message text

### Reliable notifications

Receive optional notifications for new activity and open the relevant conversation directly from the notification.

### Built for adults

NearMeU is only for users aged 18 or older. Users must follow the community rules and applicable laws.

### Permissions

NearMeU may request:

- Location: required for nearby discovery
- Notifications: optional, used for message and account alerts
- Photos/media access: requested only when selecting a profile photo, subject to the Android version and picker behaviour

You can change permissions at any time in Android settings. Some features may stop working when required permissions are disabled.

### Account deletion

Users can delete their account from **Settings → Delete account**. Additional information is available at [ACCOUNT DELETION URL].

Privacy policy: [PRIVACY POLICY URL]

Support: [SUPPORT EMAIL OR URL]

## Suggested category

Social

## Suggested tags

- Social discovery
- Nearby people
- Private chat

Final tags depend on the options currently offered by Google Play Console.

## Content and audience declarations

- Intended audience: adults aged 18+
- Not designed for children
- User-generated profiles and private messages
- Location-based functionality
- Blocking, reporting and moderation controls available
- Ads: [YES / NO — MUST MATCH SHIPPING BUILD]

## App access instructions draft

NearMeU requires authentication and an adult profile to access the main experience.

Suggested reviewer instructions:

1. Open the app and choose the available sign-in method.
2. Complete the adult onboarding flow using the reviewer test account supplied in Play Console.
3. Grant location permission or use the test-device location configured for review.
4. The Nearby screen displays compatible test profiles when seeded test data is available.
5. Open a test profile to access private chat, blocking and reporting controls.
6. Open Settings to verify notification preferences, logout and account deletion.

Do not put reusable production passwords in this repository. Add temporary reviewer credentials only inside the protected Play Console App access section.

## Release notes — first internal test

Initial NearMeU internal-testing release.

- Adult nearby discovery
- Private one-to-one messaging
- Replies, seen status, unsend and delete-for-me
- Push notifications
- Blocking and reporting
- Spam and abuse protections
- Secure logout and account deletion
- Crash and performance monitoring

## Screenshot plan

Prepare phone screenshots from the exact release candidate. Never show real user data, private chat text, email addresses, exact coordinates or test credentials.

1. Welcome/sign-in screen
2. Adult onboarding and privacy explanation
3. Nearby discovery grid/list with synthetic profiles
4. Public profile details
5. Private chat with synthetic text
6. Block/report safety controls
7. Notification preferences
8. Account deletion screen

## Feature graphic brief

- Canvas: use the current Google Play required dimensions
- Brand: NearMeU name/logo
- Message: “Discover nearby. Connect privately.”
- Visuals: abstract map/proximity shapes and chat elements
- Do not imply guaranteed dating outcomes, exact live tracking or anonymous/unmoderated use
- Do not include real personal data or misleading device frames

## Pre-publish copy checklist

- [ ] Privacy-policy URL is public and reachable without login
- [ ] Account-deletion URL is public and reachable without login
- [ ] Support contact is monitored
- [ ] Description matches the exact release candidate
- [ ] Permissions text matches the final Android manifest and runtime prompts
- [ ] Ads declaration matches the product
- [ ] Screenshots contain only synthetic test data
- [ ] No statement promises perfect security, guaranteed matches or continuous exact tracking
- [ ] Age/audience declarations match onboarding and Play Console
