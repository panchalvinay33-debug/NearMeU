# NearMeU physical Android device testing

This guide covers short-lived installation and validation of the CI-built debug APK on a physical Android phone. The debug APK is for engineering testing only and must not be uploaded to Google Play or shared as a production release.

## Install the CI APK

1. Download the `nearmeu-debug-apk-*` artifact from the successful GitHub Actions run.
2. Extract the ZIP and copy `app-debug.apk` to the Android phone.
3. On the phone, allow **Install unknown apps** only for the file manager or browser used to open the APK.
4. Open `app-debug.apk` and install it.
5. Disable the temporary **Install unknown apps** permission after installation.

A previous NearMeU debug build signed with a different debug certificate may need to be uninstalled first. Uninstalling clears local app data.

## Required test setup

- Two Android phones are preferred so chat, notifications, blocking, and presence can be tested between two accounts.
- Use two test accounts with completed adult profiles.
- Keep location, notification, and internet permissions enabled when testing their related flows.
- Debug builds use the Firebase App Check debug provider. Register the device's App Check debug token in the intended Firebase project before testing protected callable Functions.

## Smoke-test checklist

- Fresh install and launch
- Google sign-in and logout
- New-user onboarding and profile completion
- Location permission and nearby discovery
- Open another profile and start a chat
- Send messages, reply, seen state, unsend, and delete-for-me
- Background and foreground notification behavior
- Open the correct chat from a notification
- Message rate-limit response
- Report, block, and unblock behavior
- Online/offline presence
- Account suspension handling
- Account deletion with Google reauthentication
- Relaunch after force-stop and after device restart

## Record failures

For every issue, record:

- Exact steps
- Expected and actual result
- Phone model and Android version
- NearMeU commit SHA and APK artifact name
- Screenshot or screen recording when appropriate
- Whether the issue reproduces on the second device/account

Do not capture or post private message content, account tokens, exact coordinates, or other users' personal information in public issue reports.
