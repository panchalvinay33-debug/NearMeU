# NearMeU Approved Product Decisions

Last updated: 2026-07-31

This file freezes owner-approved product behavior that future implementation batches must follow. It records intended behavior, not a claim that every item is already implemented.

## 1. Product simplicity

NearMeU uses one clear Premium plan. There are no coins, separate calling packs, public Premium badges, tier ladders or confusing trials in the approved design.

Free users can use core social discovery and text communication. Premium unlocks outbound private media, outbound calling and extended automatic recovery.

## 2. Premium access

Premium unlocks:

- Send photos.
- Send videos.
- Send voice messages.
- Start voice calls.
- Start video calls.
- Automatic recovery of eligible chats and media for up to six months.

Premium status is private and is not displayed to other users.

Free users can:

- Send and receive text.
- Receive/view photos and videos.
- Receive/play voice messages.
- Receive, accept or reject incoming voice/video calls.
- Use Clear Chat, block and report.

A Free user cannot initiate photo, video, voice-message or calling actions. Locked controls remain visible so the feature and Premium requirement are clear.

## 3. Premium purchase continuation

When a Free user taps a locked feature and purchases Premium successfully, the original intended action should continue automatically where safe:

- Photo action opens the picker.
- Video action opens the relevant picker/camera flow.
- Voice action starts the voice-message flow after permission checks.
- Calling action proceeds to the call flow.

## 4. Media storage and retention

### Local device

After successful local download/save, text, photos, videos and voice messages remain in NearMeU app-private storage until one of these events:

- Clear Chat.
- Applicable Delete for Me/Delete for Everyone action.
- App data is cleared.
- App is uninstalled.

Seven-day cloud cleanup must not delete valid local files.

### Temporary delivery cloud

The temporary media-delivery copy may remain in NearMeU-managed cloud storage for up to seven days. Its purpose is reliable sender-to-receiver delivery, not long-term recovery.

After delivery-cloud expiry:

- Local files remain usable.
- No expired placeholder is shown when a valid local file exists.
- A device that never downloaded the file cannot recover it from the delivery copy after deletion unless a separate eligible Premium backup exists.

### Premium recovery backup

Eligible Premium chat and media data is backed up automatically for up to six months under a per-user recovery entitlement.

Eligible recovery can include:

- Text messages.
- Sent and received downloaded photos.
- Sent and received downloaded videos.
- Sent and received downloaded voice messages.
- Timestamps, replies and conversation context.
- Call-history metadata.

Actual voice/video calls are never recorded or backed up.

Clear Chat permanently removes that user's recoverable copy. Premium expiry does not immediately erase items whose retention was validly assigned while Premium was active; they expire according to their recorded retention unless the user clears or permanently deletes them.

## 5. Message state and ticks

Approved meaning:

- Pending/spinner: device is preparing or submitting the message.
- Single tick: server accepted the message.
- Grey double tick: receiver device synchronized/delivered the message.
- Blue double tick: receiver opened/read the message.
- Failed/retry: the message was not successfully accepted.

Delivered and read are separate facts and must not be represented by one boolean.

## 6. Clear Chat

Every individual chat screen has `Clear Chat` in the top-right three-dot menu.

When a user confirms Clear Chat:

- All messages, local media, voice notes and call-history entries are removed for that user.
- The user's cloud recovery copy and all of that user's devices are cleared.
- The conversation disappears from that user's chat list.
- It is permanently non-recoverable for that user, including after reinstall or Premium restore.
- The other participant's copy is unaffected.

Clear Chat, Delete for Me and Delete for Everyone are separate behaviors.

## 7. Identity continuity

One verified email maps to one continuing NearMeU identity.

- Reinstall and phone change use the same identity.
- Account Close followed by login with the same verified email reactivates the same identity.
- Existing relationships and block records continue.
- Cleared chats and permanently deleted content do not return.
- Duplicate active identities from the same verified email are not created.

## 8. Account Close

Account Close is reversible reactivation, not permanent data deletion.

On Close Account:

- Public name, profile photo, bio, discoverability and public location/profile details are removed or made unavailable.
- The account is removed from Nearby/search.
- New messaging/calling is disabled.
- Other users see a neutral `Account unavailable` state.
- Internal identity, block relationships and permitted recovery continuity remain.

On same-email reactivation:

- The same internal identity returns.
- The user recreates public profile details.
- Existing blocks remain active in both directions.
- Uncleared, still-retained conversations can continue.

A separate Permanently Delete Account flow must exist for irreversible deletion and required disclosures.

## 9. Blocking

Blocks survive:

- App reinstall.
- Phone change.
- Account Close.
- Account reactivation.

Profile-sharing links cannot bypass a block, suspension or closed/unavailable account.

## 10. Calling

Agora RTC is the selected managed calling provider for the planned implementation.

- Firebase/NearMeU controls identity, authorization, incoming notifications, call state, blocks, Premium and call history.
- Agora carries live audio/video.
- Call initiation requires Premium.
- Call receipt is available to Free and Premium users.
- Calls are not recorded.
- Audio calling is completed and accepted before video calling begins.

## 11. Profile sharing

Free and Premium users can share their own profile through a revocable public profile link.

- Installed app opens the profile directly.
- Without the app, a limited web preview and Play Store route are shown.
- Install/referrer flow attempts to resume the shared profile.
- Public links never reveal internal Firebase UID, email, phone number or exact location.
- Users can disable sharing or reset the public link.

## 12. Owner-only administration

The current product has one owner administrator. Multi-admin roles and permission matrices are deferred to avoid unnecessary complexity.

Owner administration includes:

- Existing user management and suspension/restore.
- Active Premium user count.
- Premium user list and source.
- Timed or custom-date Premium grants.
- Premium extension.
- Revocation of an admin-granted entitlement.
- Owner action audit record.

Removing an admin grant does not silently cancel a valid Google Play purchase.

## 13. Deferred features

Not in the current execution path:

- Multi-admin roles.
- Public Premium badge.
- Multiple Premium tiers.
- Coins or credits.
- Group calls.
- Call recording.
- Long-form video platform features.
- iOS release before Android production acceptance.

## 14. Implementation-status language

Documents and UI specifications must distinguish:

- Implemented and tested.
- Implemented but not fully tested.
- Partially implemented.
- Planned/approved.
- Deferred/rejected.

An approved product decision is not evidence that the code already implements it.