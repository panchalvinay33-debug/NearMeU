# Batch09 Call Notification Policy

Status: Batch09 implementation rule. This branch remains WIP and must not be merged or deployed until Base08 final closeout and reconciliation with accepted main.

## Separate Android notification channel

NearMeU calls use the dedicated Android notification channel `nearmeu_calls` (display name: `NearMeU Calls`). Message and general app notifications remain on their separate notification channel.

This separation is mandatory so users can control call alerts independently from message alerts.

## User controls

The Calls screen exposes a shortcut to the Android notification settings for `NearMeU Calls`.

Android owns the final channel preference. Depending on device/Android version, users can choose behavior such as:

- sound and vibration;
- vibration-only or equivalent reduced-alert behavior;
- silent;
- disable call notifications completely.

NearMeU must not silently overwrite a user's Android channel choice after the channel has been created.

## Incoming-call behavior

- Active call alerts use the dedicated call channel and call-category/high-priority presentation where Android permits it.
- Full-screen incoming-call presentation must respect Android notification permission/channel state and platform restrictions.
- If the user silences the call channel, NearMeU must not attempt to force ringtone playback outside that channel to defeat the user's choice.
- If call notifications are disabled, background or killed-app incoming calls may not be surfaced reliably; this is a platform/user-setting consequence and must not be disguised as guaranteed delivery.
- Do Not Disturb bypass is not enabled by default and NearMeU must not request or force DND bypass as part of Batch09.

## Scope separation

- Message notification mute and call notification mute are independent.
- Per-user call muting is not part of the minimum Batch09 acceptance scope unless separately unlocked; block rules already prevent blocked users from calling.
- Batch10 video calls will reuse the same `NearMeU Calls` notification policy unless a later accepted scope explicitly changes it.

## Physical acceptance

Before Batch09 can be accepted, two-phone testing must include at least:

1. normal call notifications with sound/vibration enabled;
2. call channel set to silent and an incoming call received;
3. call channel disabled and resulting behavior documented;
4. message notifications verified unaffected by call-channel changes;
5. DND behavior verified without NearMeU bypassing system policy;
6. foreground, background, and killed-app incoming-call scenarios tested with the relevant notification setting.
