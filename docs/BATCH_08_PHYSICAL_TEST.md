# Batch 08 Physical Acceptance — Profile Sharing and Deep-Link Recovery

Status: **CI PASS / DEPLOYMENT + PHYSICAL ACCEPTANCE PENDING**

Target version: `1.0.11+12`

Branch: `batch/08-profile-sharing-deep-link-recovery`

Authoritative branch head: `c8210ca2591cd843eb5edcedef284892d82db435`

Base / promoted Batch 07 recovery state: `ff551ceb48d3fc1d957141977df29ebb31837b87`

## Frozen scope

- Free and Premium users can share their own profile.
- Sharing is explicit opt-in: opening the settings screen does not silently create/enable a public link.
- Shared links use an opaque, revocable public identifier; Firebase UID, verified email, phone number and exact location are never placed in the public URL or public web preview.
- Android installed-app handling uses the verified Firebase Hosting URL plus a NearMeU custom-scheme fallback.
- Without the app, the shared URL shows a generic privacy-safe NearMeU landing preview and a Play Store route; personal profile details are resolved only inside the authenticated app.
- A signed-in active app user resolves the public identifier through a trusted callable before opening the profile.
- Block relationships are checked both ways before app-side resolution; a block cannot be bypassed with a shared link.
- Suspended, closed or permanently deleted accounts do not resolve because an active shareable `users/{uid}` profile is required.
- Users can disable sharing and reset/revoke the current public link.
- Resetting a disabled link preserves the disabled state and never silently re-enables sharing.
- Permanent Auth UID deletion removes the current profile-sharing owner/link mapping.
- Existing chat, Premium, six-month recovery, Clear/Delete, seven-day delivery-cloud, package and signing behavior remain unchanged.
- No Agora calling, owner-Premium admin or Play purchase verification work is in Batch 08.

## Implementation paths

- `functions/profile_sharing_logic.js`
- `functions/profile_sharing_functions.js`
- `functions/bootstrap.js`
- `firebase.json`
- `hosting/public/.well-known/assetlinks.json`
- `hosting/public/index.html`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/nearmeu/nearmeu/MainActivity.kt`
- `lib/services/profile_sharing_service.dart`
- `lib/widgets/deep_link_lifecycle.dart`
- `lib/screens/profile_sharing_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/main.dart`
- `rules_tests/profile_sharing.test.js`

## Automated gate evidence

- Build recoverable base APK #86 / run `30749349760`: **PASS**.
- NearMeU quality gate #489 / run `30749349765`: **PASS**.
- Flutter format: **PASS**.
- Flutter analyze: **PASS**.
- Flutter tests: **PASS**.
- Cloud Functions unit/load checks: **PASS**.
- Firebase Rules emulator tests: **PASS**.
- Permanent signing verification: **PASS**.
- Android package: `com.nearmeu.nearmeu` unchanged.
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`.

### Recoverable signed debug artifact

- Artifact ID: `8834050185`.
- Artifact digest: `sha256:65a8465f3387c776bc20f938ccf12c22b39913c879c0dbbdef78cbeca7ec1b7e`.
- Signed debug APK SHA-256: `82bee077a8b7c0533376283ce01de903b617400824979b34d5b596a125693bd5`.

### Signed release artifact

- Artifact ID: `8834130859`.
- Artifact digest: `sha256:cdc53cb2885184a42d1ddc47c57208057c65f896d0e84278ce7785997da78ec2`.
- Signed release APK SHA-256: `b8b66c4d719359bc9a92e3dd6dfa57174b12580844904150e9d24832c1e3a51f`.

GitHub Actions checks out the PR merge ref for build execution, so generated artifact names/manifests may contain merge-ref SHA `4f3dfbfb12ff0947455d0e27032b65b233c78f01`. The authoritative Batch 08 branch head for acceptance remains `c8210ca2591cd843eb5edcedef284892d82db435`; these values must not be conflated.

## Production actions before complete physical test

Deploy only the Batch 08 profile-sharing Functions and Firebase Hosting from the exact branch/head above. Existing Firestore/Storage rules are not part of this deployment because those runtime rule files did not change in Batch 08.

Deployment is not acceptance; owner physical testing follows deployment.

## Focused owner matrix

1. Install Batch 08 APK with `adb install -r`; no uninstall/data wipe. Existing login/chat/media remains intact.
2. Settings → Share My Profile opens with sharing OFF for a user who has never enabled it.
3. Turning sharing ON creates an HTTPS link using an opaque public identifier, not UID/email/exact location.
4. Android share sheet opens with the profile URL.
5. Opening the HTTPS link on the installed tested app resolves to the correct profile.
6. Opening the custom `nearmeu://profile/...` fallback resolves to the same profile.
7. Cold-start link: app closed → link opened → after authenticated startup the correct profile opens once.
8. Warm-start link: app already running → link opens the correct profile once without duplicate navigation.
9. Disabled sharing: old link becomes unavailable in app and web preview.
10. Re-enable sharing: current link becomes available again.
11. Reset link while ON: old URL no longer resolves; new URL resolves and sharing remains ON.
12. Reset link while OFF: identifier changes but sharing remains OFF; new link does not resolve until explicitly enabled.
13. Block bypass test: block either direction, then shared link must not open the blocked profile in app.
14. Unblock restores normal resolution when link remains enabled.
15. Suspended/closed/unavailable account shared link does not expose profile.
16. Web preview is generic and reveals no nickname, age, UID, email, phone number or location; detailed profile data is app-only after authenticated authorization.
17. Regression smoke: Nearby, Chats, text send, media availability, Clear/Delete semantics and Premium recovery startup remain normal.

## Owner decision

`PENDING` until required production deployment, focused physical tests and owner acceptance are complete.
