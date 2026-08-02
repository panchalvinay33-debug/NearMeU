# Batch 08 Physical Acceptance — Profile Sharing and Deep-Link Recovery

Status: **IMPLEMENTATION / CI / DEPLOYMENT / PHYSICAL ACCEPTANCE PENDING**

Target version: `1.0.11+12`

Branch: `batch/08-profile-sharing-deep-link-recovery`

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

## Automated gates required

1. Flutter format — PASS required.
2. Flutter analyze — PASS required.
3. Flutter tests — PASS required.
4. Cloud Functions load/tests including `profile_sharing_logic.test.js` — PASS required.
5. Firebase Rules tests including direct client denial for internal share mappings — PASS required.
6. Permanent signing restored/verified — PASS required.
7. Signed debug/recoverable APK — PASS required.
8. Signed release APK — PASS required.
9. Android package stays `com.nearmeu.nearmeu`.
10. Permanent signing certificate stays unchanged.

## Production actions before complete physical test

Batch 08 requires deployment of the new profile-sharing callables/function plus Firebase Hosting configuration/content so the public HTTPS URL and `assetlinks.json` are real. Deployment is not acceptance; owner physical testing follows deployment.

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

`PENDING` until fresh CI, permanent signed APK, required production deployment, focused physical tests and owner acceptance are complete.
