# NearMeU V1 Launch Product Decisions

Last updated: 2026-08-08

This document contains only product behavior that matters to the current V1 launch. It does not define a future feature roadmap.

## 1. Authentication and profile

- Android-first Google/Firebase sign-in remains the entry identity.
- A complete existing profile must open the app without repeating onboarding.
- An account with no complete profile may enter onboarding.
- Profile details must not be silently replaced during ordinary sign-in/reactivation.
- Explicit profile edits remain the normal way to change user-entered profile details.

## 2. One continuing account identity

For the V1 launch behavior, ordinary account exit is treated as deactivation/reactivation rather than destructive identity replacement.

Required behavior:

- one account does not create duplicate NearMeU identities during normal use;
- deactivation preserves the internal identity, existing profile and existing uncleared chats;
- deactivated users are unavailable for current discovery/activity;
- existing counterpart chats show a neutral deactivated-account state;
- signing in again with the same account reactivates the same identity;
- reactivation restores the same profile and uncleared chats without onboarding;
- irreversible permanent deletion, if exposed, must be clearly separate from normal deactivation.

## 3. Public and private profile separation

- `users/{uid}` is public/discovery data.
- `privateProfiles/{uid}` stores private email, exact location and private settings/notification data.
- Legacy accounts must be migrated safely before launch where possible.
- Missing personal data is never invented during migration.
- Existing profile values are not normalized or changed silently unless a specific safe migration rule requires it.

## 4. Private messaging

The current V1 supports one-to-one private chat, including text and the currently implemented private media flows.

Message-state meaning for launch:

- pending/spinner = client is preparing/submitting;
- single tick = server accepted;
- grey double tick = receiver device synchronized/delivered;
- blue double tick = receiver opened/read;
- failure/retry = message was not successfully accepted.

Delivery and read are separate facts. Unread state must agree across Chats, Chat screen and restart.

## 5. Presence and last activity

All user-facing surfaces use one presence truth:

- user is online only while NearMeU is foreground/resumed;
- background/minimized/sign-out is offline as soon as lifecycle/network conditions permit the update;
- stale online state expires through freshness protection;
- Nearby, Chats and Chat screen use the same effective-online calculation and last-seen source;
- green dot means effectively online, not merely a stored stale boolean.

## 6. Current Firebase/storage behavior

- Firestore contains chat/message metadata and text messages.
- private chat media uses the V1 Firebase Storage paths/rules.
- V1 message/media lifecycle and retention behavior is governed by the currently deployed V1 Functions and rules.
- later recovery/calling/profile-sharing systems are not part of the current V1 launch backend.

## 7. Blocking, reporting and owner admin

Existing V1 block/report controls remain part of launch testing. The current owner-admin model remains in place and must continue to work after launch-stability changes.

## 8. Scope boundary

No additional product feature is approved for implementation merely because an old document, branch, issue, PR or commit mentioned it.

Anything not required to make this current V1 stable and launch-ready is deferred to **V2 AFTER V1 LAUNCH** and will be reconsidered after V1 release.