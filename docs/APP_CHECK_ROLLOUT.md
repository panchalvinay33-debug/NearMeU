# NearMeU App Check rollout

NearMeU initializes Firebase App Check before any other Firebase-backed service.

- Android release builds use Play Integrity.
- Apple release builds use App Attest with Device Check fallback.
- Debug builds use the Firebase App Check debug provider.
- Authenticated callable Cloud Functions reject missing or invalid App Check tokens.

## 1. Register the production apps

In Firebase Console, open **Security > App Check** and register every NearMeU app before deploying App Check-enforced functions.

### Android

1. Register package `com.nearmeu.nearmeu` with the Play Integrity provider.
2. Enable the Play Integrity API for the linked Google Play app.
3. Verify that the release/upload certificate and Play Console app configuration belong to the same production app.
4. Choose Play Integrity verdict requirements that match the actual distribution channel. Do not require Play-only verdicts if APKs will also be distributed outside Google Play.

### Apple

Register the Apple app with App Attest. The client falls back to Device Check on devices where App Attest is unavailable.

## 2. Configure development devices safely

Debug builds intentionally use the App Check debug provider so emulators and local development remain possible.

1. Run a debug build and trigger a Firebase request.
2. Copy the App Check debug token from the local device logs.
3. Add that token under **Manage debug tokens** for the registered Firebase app.
4. Store CI debug tokens only in encrypted CI secrets when integration tests require real Firebase access.

Never commit, paste into documentation, or share an App Check debug token. Revoke a token immediately if it is exposed.

## 3. Deploy the client and callables

1. Confirm the Android/iOS app registrations are active in App Check.
2. Register the development device token required for local testing.
3. Build and test the updated client.
4. Deploy Cloud Functions. The following callable endpoints require valid App Check tokens:
   - `registerDeviceToken`
   - `unregisterDeviceToken`
   - `unregisterAllDeviceTokens`
   - `deleteCurrentAccount`
5. Verify sign-in, token registration, logout, push delivery, and account deletion on a registered physical device.

Scheduled account cleanup and Firestore message-created push triggers are trusted backend events and do not use callable App Check validation.

## 4. Roll out Firebase product enforcement

The client starts attaching App Check tokens after this release, but Firebase Console enforcement for products such as Cloud Firestore and Authentication must be enabled separately.

1. Ship the App Check-enabled client to testers.
2. Monitor valid, invalid, and unknown request metrics in Firebase Console.
3. Resolve legitimate invalid traffic before enforcement.
4. Enable enforcement product by product, beginning with Cloud Functions metrics verification, then Cloud Firestore, and finally Authentication when its metrics are healthy.
5. Watch error rates after every enforcement change and keep a rollback plan for each product.

Do not enable product-wide enforcement before every legitimate app variant is registered, or older/unregistered clients will lose backend access.
