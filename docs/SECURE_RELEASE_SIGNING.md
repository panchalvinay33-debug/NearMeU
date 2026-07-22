# Secure Android release signing

NearMeU release builds must never use the Android debug key.

## One-time setup

1. Generate a private upload keystore on a trusted machine.
2. Keep the keystore outside the repository.
3. Copy `android/key.properties.example` to `android/key.properties`.
4. Replace the placeholders with the real local paths and passwords.
5. Store encrypted backups of the keystore and credentials in two secure locations.
6. Enable Google Play App Signing when the first production bundle is uploaded.

## Verification

Run:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The build deliberately fails when `android/key.properties` is absent. This prevents an unsigned or debug-signed bundle from being mistaken for a production artifact.

Never share or commit `.jks`, `.keystore`, `key.properties`, service-account JSON, or Firebase Admin credentials.
