# NearMeU Android mobile smoke test

Use this checklist only with an APK produced by the green GitHub Actions quality gate. The debug APK is for controlled testing and is not a Play Store release build.

## Install

1. Download the `nearmeu-debug-apk-*` workflow artifact and extract the ZIP.
2. Copy `app-debug.apk` to an Android phone.
3. Allow installation from the browser or file manager when Android asks.
4. Install NearMeU. If an older debug build has a conflicting signature, uninstall the older debug app first.

## Test accounts

Use two adult test accounts on two physical Android phones where possible. Do not use private personal conversations or real sensitive profile information during testing.

## Smoke-test flow

- Launch the app and confirm it does not crash.
- Sign in with Google and complete onboarding.
- Grant notification and location permissions.
- Confirm nearby discovery loads and respects the distance filter.
- Open a profile and start a chat.
- Send and receive messages between two accounts.
- Verify reply, seen, unsend, and delete-for-me.
- Send messages rapidly and confirm the trusted rate limit blocks spam.
- Submit a report and confirm duplicate/report-limit handling.
- Block the second account and confirm discovery/chat access is removed both ways.
- Unblock and confirm normal access returns.
- Put the app in the background and confirm presence changes appropriately.
- Tap a push notification and confirm the correct private chat opens without message text being exposed in the notification payload.
- Log out and confirm the device notification token is unregistered.
- Test account deletion only with a disposable account and confirm reauthentication is required.

## Record results

Record the APK commit SHA, phone model, Android version, test-account names, passed/failed steps, screenshots of failures, and exact error messages. Never publish authentication tokens, Firebase debug tokens, private messages, email addresses, exact coordinates, or signing material in an issue.