# Batch 09 Physical Acceptance — Agora Audio Calling

Status: **IMPLEMENTATION / FINAL CI / CREDENTIAL DEPLOYMENT PENDING**

Target version: `1.0.12+13`

Branch: `batch/09-agora-audio-calling`

Accepted Batch 08 base: `7f8b0c1f147a8de420ac54fa25c215fc22a7b299`

## Frozen scope

- Android 1-to-1 audio calling only.
- A trusted active Premium entitlement is required to initiate an audio call.
- Free and Premium users may receive, accept, decline and participate in an incoming audio call.
- Agora App Certificate is backend secret material and is never embedded in Flutter, Android resources, Firestore or documentation.
- Agora RTC access tokens are issued only by trusted App-Check-protected Cloud Functions and are short-lived.
- Caller/callee active-profile checks and bidirectional block checks are backend enforced.
- One active audio call per user; stale active-call pointers expire rather than permanently locking a user.
- Call states: ringing, accepted, declined, ended, missed, expired.
- Ring timeout is server-authoritative; terminal states release both participants' active-call pointers.
- Incoming calls use existing authenticated FCM-device registrations and a dedicated high-priority NearMeU call notification route.
- Incoming notification navigation uses existing app-shell readiness/deduplication discipline.
- Microphone mute and speaker-route controls are included.
- Agora video/camera publishing is disabled in Batch 09; video calling is Batch 10.
- Actual call audio is not recorded, uploaded, stored in chat media, or included in seven-day delivery storage or Premium recovery.
- Existing chat, media, Clear/Delete, Premium recovery and profile-sharing behavior must remain unchanged.

## Dependency-resolution checkpoint

- Agora Flutter `6.6.3` was rejected by CI because its `ffi` constraint conflicts with the app's accepted `package_info_plus 8.3.1` dependency.
- Batch 09 therefore pins the compatible stable Agora Flutter `6.5.4` line.
- The resolved Flutter lockfile now records `agora_rtc_engine 6.5.4`.
- Functions use the maintained `agora-token` package and its resolved lockfile is committed.
- Temporary dependency-lock resolver workflows have been removed; final acceptance requires normal repository CI on a non-bot-authored Batch 09 head.

## Trusted backend surface

- `startAudioCall`
- `getAudioCall`
- `respondAudioCall`
- `endAudioCall`
- `expireStaleAudioCalls`
- `purgeAudioCallOnAuthDelete`

Internal server-owned collections:

- `audioCalls/{callId}`
- `activeAudioCalls/{uid}`

Existing Firestore catch-all rules deny direct client reads/writes to unlisted collections. The app uses trusted callables rather than direct access.

## Required production setup before physical call test

Create/use the owner-controlled Agora project for NearMeU and configure the following Firebase Function secrets without placing their values in source control, screenshots, documentation or chat:

- `AGORA_APP_ID`
- `AGORA_APP_CERTIFICATE`

Then deploy only the Batch 09 audio-call Functions. Do not deploy Batch 10 video work because it does not exist in this batch.

## Focused physical matrix

1. Install the fresh permanently signed Batch 09 APK with `adb install -r`; do not uninstall or wipe app data.
2. Existing login, Nearby, Chats, profile sharing and prior chat/media remain present after update.
3. Free caller opens another active user's profile and taps Audio Call → backend denies initiation with clear Premium-required feedback; no call is created for the receiver.
4. Premium caller taps Audio Call → outgoing screen opens and shows ringing state.
5. Free receiver gets the incoming-call notification and can open the incoming call screen.
6. Premium receiver also can receive/accept; receiving must not depend on Premium entitlement.
7. Receiver declines → caller exits/updates to declined; both users can start/receive a later call.
8. Receiver accepts → both devices join the same Agora audio channel and two-way voice is audible.
9. Caller mute → receiver no longer hears caller; unmute restores audio.
10. Speaker toggle changes Android audio route without ending the call.
11. Caller hangs up → receiver exits/updates promptly and both active-call pointers are released.
12. Receiver hangs up → caller exits/updates promptly and both active-call pointers are released.
13. Ringing call left unanswered → becomes missed after the server ring window and does not lock either user.
14. Try a second simultaneous call while either user already has an active call → backend rejects overlap.
15. Block relationship before call initiation → initiation unavailable.
16. Establish an incoming invite, then create a block before accept/refresh → trusted backend refuses continuation and the old invite cannot bypass the block.
17. Suspended/missing/unavailable account call access is backend denied; destructive owner-account suspension is not required if automated/backend evidence is sufficient.
18. Foreground incoming-call notification opens the correct call once.
19. Background/warm-start notification opens the correct call once.
20. Cold-start notification queues until authenticated app shell is ready, then opens the correct call once.
21. Deny microphone permission → call screen reports that microphone permission is required and does not silently publish audio.
22. Regression smoke: Nearby, Chats, text send, photo/video/voice-message availability, profile-sharing deep link, Clear/Delete semantics startup and Premium recovery startup remain normal.

## Security/negative evidence required

- Free initiation denied server-side, not merely hidden in UI.
- Non-participant cannot obtain call state or RTC credentials.
- App Certificate absent from APK/source/docs.
- Public/profile identifiers are not used as Agora secrets.
- Direct Firestore client access to call-state collections remains denied by catch-all rules.
- Block/suspended checks are enforced by trusted callables.
- No call audio file is persisted by NearMeU.

## Owner decision

`PENDING` until fresh CI, permanent signing, Agora/Firebase secret setup, targeted Functions deployment, fresh direct-update APK and focused physical acceptance are complete.
