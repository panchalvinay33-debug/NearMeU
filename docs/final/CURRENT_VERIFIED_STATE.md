# NearMeU — Current Verified State

Last verified: 2026-07-30 (IST)

## Canonical baseline

- Default branch: `main`
- Official recovery branch: `stable/official-base-v1-2026-07-30`
- Official base merge commit: `a743ffa407c145b3852c547d31f33458e8e839b4`
- Firebase Android package: `com.nearmeu.nearmeu`
- Permanent signing SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- Permanent signing SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Physically verified on Android

- App installs and launches.
- Google Sign-In succeeds with the permanent SHA OAuth client.
- Firebase App Check debug token registration works after reinstall.
- Nearby discovery loads after App Check registration.
- Future trusted debug updates can use `adb install -r -t` while the permanent signing key is retained.

## CI protection

`main` is protected by an active GitHub ruleset. Every merge must use a pull request and pass:

- `Flutter checks`
- `Firebase rules tests`
- `Cloud Functions checks`

Deletion and force-push are blocked for `main`.

## Important boundaries

- Debug builds use the App Check debug provider and may need a new token after reinstall or app-data reset.
- Release builds use Play Integrity and must be tested through a Play testing track.
- Green CI proves source/build/test health, not that Firebase rules, indexes, Storage rules or Functions are deployed.
- Git does not store the keystore, signing passwords, App Check tokens, Firebase Console state, Play Console state or live production data.

## Next safe work

Start every change from current `main` on a focused branch, open a pull request, wait for all required checks, test runtime changes on a real Android device, and update the roadmap/recovery records before replacing the official base.