# NearMeU Batch09/10 Calling Scope

Status: agreed planning scope; implementation remains locked until owner unlocks the relevant batch.

Provider: Agora RTC. See `docs/RTC_PROVIDER_AGORA.md`.

## Batch split

- Batch09: one-to-one audio calling.
- Batch10: one-to-one video calling built on the accepted Batch09 call lifecycle and audio-routing foundation.

## Primary call entry point

The primary call controls live in the top-right of the private chat header, beside the user identity/status area.

Target order:

`user photo / name / status        audio call        video call        overflow`

Rules:

- Batch09 exposes the audio-call control.
- Batch10 introduces/enables the video-call control.
- Before Batch10 acceptance, the video control should be hidden rather than shown as a dead/disabled button.
- Nearby/discovery lists do not receive direct call icons by default, to avoid clutter and accidental calls.
- A profile page may later expose secondary call actions, but the private-chat header remains the canonical primary entry point.

## Audio-call controls and routing

Batch09 must provide:

- mute / unmute;
- end call;
- speaker toggle;
- earpiece route;
- Bluetooth headset / earbuds / speaker route;
- wired-headset route where Android exposes it;
- safe route fallback if Bluetooth or wired audio disconnects during a call;
- live route refresh when an audio device connects, disconnects, or reconnects during an active call.

Bluetooth acceptance includes at least connect-before-call, receive-on-Bluetooth, connect-during-call, disconnect-during-call, and reconnect/switch scenarios.

## Proximity-sensor behavior

Audio calls must use Android proximity behavior to reduce accidental touches:

- when the active route is the phone earpiece and the device is brought to the ear, the display should turn off/dim and touch interaction should be suppressed as appropriate;
- when the device moves away from the ear, the display should restore promptly;
- proximity blanking must not unnecessarily activate while the call is routed to speaker, Bluetooth, or an external wired device;
- behavior must fail safely on devices without a usable proximity sensor.

## Incoming / outgoing call experience

The app must provide clear outgoing-ringing and incoming-call states. Incoming calling should use a large/full call UI that clearly shows the caller identity and call type, with explicit accept and reject actions.

The call lifecycle must distinguish at least:

- starting;
- ringing;
- accepted / connecting;
- connected;
- rejected;
- caller-cancelled;
- missed / timeout;
- failed;
- ended.

Duplicate or stale state transitions must be idempotent and must not leave a call stuck in ringing/connected state.

## Video-call controls and privacy

Batch10 adds:

- camera on/off;
- front/back camera switch;
- reuse of Batch09 mute, speaker, audio-device routing, reconnect and end-call controls;
- background blur/privacy blur where device/provider capability and performance are sufficient;
- camera-off fallback showing a safe avatar/placeholder instead of a stale frame;
- a performance-safe fallback for devices that cannot run live blur reliably.

Background blur is a privacy feature, not a guarantee that all identifying background content can never be inferred. Camera-off remains the stronger privacy control.

## Screenshot and screen-recording policy

During development and physical verification, screenshot/screen-recording blocking remains OFF because screenshots are needed for evidence and debugging.

Before controlled public launch, privacy/security hardening must explicitly review and decide the final screenshot/screen-recording policy for calling screens. If blocking is enabled, it must be tested for compatibility with incoming-call UI, background/foreground transitions, and support/debug workflows.

## Security and eligibility

Calling must preserve existing NearMeU privacy/security boundaries:

- blocked users cannot call each other;
- deleted, disabled, suspended or otherwise ineligible accounts cannot initiate/continue calls as allowed by the accepted account-state rules;
- clients must not contain the Agora App Certificate or equivalent long-lived signing secret;
- production RTC access uses short-lived server-issued tokens;
- call identifiers/channels must not expose unnecessary user-identifying data;
- replay, duplicate-start and duplicate-accept/end behavior must be safely handled;
- App Check/auth enforcement must be included where supported by the backend contract.

## Reliability and recovery

The implementation must cover:

- caller cancellation before answer;
- receiver reject;
- missed/timeout;
- receiver offline;
- weak/unstable network;
- network loss and recovery during call;
- app background/foreground transitions;
- app kill/reopen recovery where Android/platform limits permit;
- stale ringing cleanup;
- simultaneous/rapid repeated call attempts;
- consistent state on both participants;
- call-history recording without resurrecting ended calls.

## Required physical acceptance scenarios

At minimum, two-device physical testing must cover:

1. normal audio call A -> B;
2. reject;
3. missed/timeout;
4. caller cancel before answer;
5. receiver offline;
6. weak network;
7. network drop/reconnect during a call;
8. app background/foreground;
9. app kill/reopen recovery behavior;
10. blocked-user attempt;
11. rapid duplicate call attempts;
12. simultaneous incoming-call conflict handling;
13. call history;
14. Bluetooth before-call / during-call connect, disconnect and reconnect;
15. wired-headset behavior when available;
16. earpiece proximity-sensor screen-off / restore behavior;
17. speaker/Bluetooth routes do not incorrectly trigger proximity blanking;
18. regression checks for chat, Premium, presence, profile sharing, deletion/recovery and Base08 accepted behavior.

Batch10 additionally requires:

- camera permission and denial paths;
- camera on/off;
- front/back camera switching;
- video reconnect;
- background blur on supported devices;
- blur fallback on lower-capability devices;
- camera-off avatar/placeholder;
- audio routing and proximity behavior regression while video calling.

## Delivery and deployment rule

Calling work must follow the permanent NearMeU start/deployment governance:

`accepted base -> fresh narrow branch -> code -> CI -> signed candidate -> focused physical test -> owner PASS -> merge -> deployment gate -> smallest safe production deployment -> production audit -> acceptance/recovery promotion`

Historical Batch09/calling branches are reference only and are never direct merge/deploy sources.
