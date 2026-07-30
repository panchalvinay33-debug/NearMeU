# NearMeU — Current Verified State

Last verified: 2026-07-30 (IST)

## Canonical working baseline

- Source commit: `48a290c58a14a71174b921832e516b568b06ba48`
- Firebase Android package: `com.nearmeu.nearmeu`
- Verified quality-gate run: `30514551494`
- Permanent signing SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- Permanent signing SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Physically verified on Android

The permanently signed debug APK was installed after removing the previous ephemeral-signature build. The following were confirmed on a real Android phone:

- Application installs and launches.
- Google Sign-In succeeds with the permanent SHA OAuth client.
- Firebase App Check debug token can be registered after reinstall.
- Nearby discovery loads after App Check registration.
- The installed package is now on the permanent signing line, so future trusted debug updates can use `adb install -r -t` without another signature-migration uninstall.

## CI-verified checks

- Flutter formatting validation
- Flutter static analysis
- Flutter tests
- Cloud Functions tests
- Firebase Rules emulator tests
- Permanent keystore restore from GitHub Actions secrets
- Permanent signing certificate verification
- Signed debug APK build and artifact upload
- Signed release APK build and artifact upload
- Signing files removed from the runner after build

## Important boundaries

- Debug APK uses the Firebase App Check debug provider. A fresh app-data reset or reinstall may require registering a new debug token.
- Release APK uses Play Integrity. Release App Check must be tested through a Play testing track before enforcement or public rollout.
- A green CI run proves source/build/test health; it does not prove that the newest Firebase rules, indexes, Storage rules or Functions are deployed.
- Do not delete the stable/backup branches or rotate signing secrets without recording a replacement recovery point.

## Recovery branches

All branches below were created from the verified baseline commit:

- `stable/permanent-signed-2026-07-30`
- `backup/pre-final-lock-2026-07-30`
- `release/permanent-signed-v1`
- `snapshot/working-app-check-2026-07-30`

## Next safe work

All new application work must start from current `main` after the final documentation PR is merged. Use a focused branch and PR, require a green quality gate, test on a real device, and preserve this baseline until the replacement release is proven better.
