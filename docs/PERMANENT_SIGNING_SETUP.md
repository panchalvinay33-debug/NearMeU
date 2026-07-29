# NearMeU permanent Android signing

NearMeU uses one private keystore for repeatable Android signatures. The keystore and passwords must never be committed.

Required GitHub Actions secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`

The quality workflow restores the keystore only on trusted `main` pushes when all four secrets are available. Pull requests continue to build with the normal ephemeral debug key and verify that unsigned release builds are refused.

## Rotation warning

Do not replace the permanent keystore after users install a build signed with it. Android will reject updates signed by another key. Keep at least two encrypted offline backups.

## Firebase

Register the permanent certificate SHA-1 and SHA-256 in the Firebase Android app before distributing its first build. Keep the existing debug fingerprints during development.
