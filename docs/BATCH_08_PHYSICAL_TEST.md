# Batch 08 Physical Acceptance — Profile Sharing and Deep-Link Recovery

Status: **ACCEPTED**

Accepted on: 2026-08-02

Target version: `1.0.11+12`

Runtime branch: `batch/08-profile-sharing-deep-link-recovery`

Tested runtime commit: `fdc9b22322a96b793fff3058b1ca990f656e80a1`

Merged main runtime commit: `f83a6e92457f728f177dc062dcc9171c141a9217`

Base / promoted Batch 07 recovery state: `ff551ceb48d3fc1d957141977df29ebb31837b87`

## Frozen scope

- Free and Premium users can share their own profile.
- Sharing is explicit opt-in; opening Profile Sharing does not silently create or enable a link.
- Shared links use an opaque, revocable public identifier; Firebase UID, verified email, phone number and exact location are not placed in the public URL or public web preview.
- Android installed-app handling uses the verified Firebase Hosting HTTPS URL plus a NearMeU custom-scheme fallback.
- The web preview is generic and privacy-safe; personal profile details are resolved only inside the authenticated app.
- A signed-in active app user resolves the public identifier through a trusted callable before opening the profile.
- Block relationships are checked both ways; a shared link cannot bypass a block.
- Suspended, closed, missing or permanently deleted profiles do not resolve.
- Users can disable sharing and reset/revoke the current public link.
- Reset while disabled preserves the disabled state.
- Permanent Auth UID deletion removes the profile-sharing owner/link mapping.
- Existing chat, Premium, six-month recovery, Clear/Delete, seven-day delivery-cloud, package and signing behavior remain unchanged.
- No Agora calling, owner-Premium administration or Play purchase verification work is included.

## Final automated gate evidence

- Build recoverable base APK #90 / run `30750777554`: **PASS**.
- NearMeU quality gate #493 / run `30750777555`: **PASS**.
- Flutter format/analyze/tests: **PASS**.
- Cloud Functions unit/load checks: **PASS**.
- Firebase Rules emulator tests: **PASS**.
- Permanent signing verification: **PASS**.
- Android package: `com.nearmeu.nearmeu` unchanged.
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`.

### Recoverable signed debug artifact

- Artifact ID: `8834500159`.
- Artifact digest: `sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49`.
- Signed debug APK SHA-256: `4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412`.

### Signed release artifact

- Artifact ID: `8834548293`.
- Artifact digest: `sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a`.
- Signed release APK SHA-256: `ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde`.

GitHub Actions built the PR merge ref `d843fbe831bede63fedd4cd69a46bdf108f5f799`; the authoritative tested runtime branch head is `fdc9b22322a96b793fff3058b1ca990f656e80a1`. These values must not be conflated.

## Production deployment

The Batch 08 profile-sharing Functions and Firebase Hosting were deployed and then operationally verified on the owner test device: the initial `getMyProfileShareLink` call loaded successfully and the public Hosting preview worked. Existing Firestore/Storage rules were not changed by Batch 08.

## Physical/backend acceptance matrix

- Direct update with `adb install -r`, same package/signing/session retained — **PASS**.
- Settings → Share My Profile loads correctly — **PASS**.
- Explicit Sharing ON generates opaque HTTPS link — **PASS**.
- Android share flow shares the profile URL — **PASS**.
- Public URL exposes no readable UID/email/phone/exact location — **PASS**.
- Generic privacy-safe web preview — **PASS**.
- HTTPS warm-start deep link opens the correct profile once — **PASS**.
- HTTPS cold-start deep link opens the correct profile once — **PASS** after same-batch navigation-race fix.
- Sharing OFF makes the current link unavailable — **PASS**.
- Re-enable restores current-link resolution — **PASS**.
- Reset while ON rotates to a new link; old link becomes unavailable; new link resolves — **PASS**.
- Reset while OFF preserves disabled state — **owner-reported PASS**.
- Bidirectional block bypass prevention — **owner-reported PASS plus backend-enforced evidence**.
- Unblock restores normal resolution — **owner-reported PASS**.
- Suspended/missing/unshareable profile rejection — **backend-enforced PASS**; destructive owner-account suspension/deletion was not required for physical acceptance.
- Permanent Auth-delete mapping cleanup — **backend-trigger implementation + automated checks PASS**.
- Regression smoke: Nearby, Chats, text/media and existing app behavior — **owner-reported PASS**.

## Known evidence note

The HTTPS installed-app path was physically verified for both warm and cold starts. The custom `nearmeu://profile/...` fallback exists in the Android/client implementation but was not separately captured as an independent physical screenshot; it is not used to overstate the HTTPS physical evidence.

## Owner decision

**ACCEPTED on 2026-08-02.** Batch 08 runtime PR #100 was merged only after the final signed Build #90 / Quality #493 state passed owner testing.
