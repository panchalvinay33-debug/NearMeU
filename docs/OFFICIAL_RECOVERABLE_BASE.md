# NearMeU Official Recoverable Base

Last promoted: 2026-08-02

## Current accepted base

Batch 08 is the accepted runtime/recovery starting point for future NearMeU work after final closeout promotion.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `f83a6e92457f728f177dc062dcc9171c141a9217`
- Tested runtime commit: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Accepted pull request: `#100`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.11+12`
- Physically tested signed debug APK SHA-256: `4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412`
- Recoverable artifact ID: `8834500159`
- Recoverable artifact digest: `sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49`
- Signed release artifact ID: `8834548293`
- Signed release artifact digest: `sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a`
- Signed release APK SHA-256: `ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde`
- Build workflow: `30750777554` / #90 — PASS
- Quality workflow: `30750777555` / #493 — PASS
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED** on 2026-08-02.

Accepted evidence includes explicit opt-in profile sharing, opaque URL generation, Android share flow, generic privacy-safe Hosting preview, warm/cold HTTPS app-link navigation, disable/re-enable behavior, link rotation and old-link invalidation, block-bypass prevention and regression smoke.

Known evidence notes:

- Batch 07 receiver-media pre-download/post-download Premium recovery eligibility remains **OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS**.
- Batch 08 custom `nearmeu://profile/...` fallback is implemented but was not separately captured as an independent physical screenshot; HTTPS warm/cold handling was physically verified.

## Canonical local workspace

Owner workspace: `F:\NearMeU`.

After recovery-branch promotion, synchronize this workspace to promoted `main` before Batch 09 starts.

## Recovery procedure

```powershell
cd "F:\NearMeU"
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
git rev-parse HEAD
```

For immutable accepted runtime source only:

```powershell
git checkout fdc9b22322a96b793fff3058b1ca990f656e80a1
```

For merged-main Batch 08 runtime:

```powershell
git checkout f83a6e92457f728f177dc062dcc9171c141a9217
```

Install only an APK signed by the permanent matching certificate and use update mode (`adb install -r`). Do not uninstall or wipe normal test installations.

## Batch 08 accepted behavior

- profile sharing is explicit opt-in;
- shared URLs use opaque revocable public identifiers;
- public web preview is generic and privacy-safe;
- trusted backend resolution requires an authenticated active viewer;
- bidirectional blocks prevent link bypass;
- suspended/missing/unshareable profiles do not resolve;
- sharing OFF revokes the current link;
- re-enable restores the current link;
- reset rotates the link and invalidates the old URL;
- HTTPS warm/cold app links navigate to the correct profile;
- Auth deletion purges profile-sharing mappings;
- accepted Batch 07 chat/Premium/recovery/deletion semantics remain unchanged.

## Next approved batch

Batch 09 — Agora audio calling.

Batch 08 is closed only after final documentation merge, recovery-branch fast-forward and `F:\NearMeU` sync complete.
