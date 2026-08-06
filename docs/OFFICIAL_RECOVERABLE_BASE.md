# NearMeU Official Recoverable Base

Last reviewed: 2026-08-06

## Current rule

NearMeU's accepted product boundary is **Base 08 only**.

The exact current recovery SHA is not duplicated here. The machine-readable authority is:

`config/official_base_manifest.json`

Normal source recovery is:

```powershell
cd F:\NearMeU
.\tool\restore_official_base.ps1
```

This is the supported recovery path. Manual hunting through old PRs/branches should not be necessary.

## Project identity

- Repository: `panchalvinay33-debug/NearMeU`
- Canonical workspace: `F:\NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.11+12`
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Original Base08 acceptance — 2026-08-02

Original accepted evidence remains historically valid:

- Tested runtime commit: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Merged runtime commit: `f83a6e92457f728f177dc062dcc9171c141a9217`
- Accepted PR: `#100`
- Original closeout commit: `7f8b0c1f147a8de420ac54fa25c215fc22a7b299`
- Build workflow `30750777554` / #90 — PASS
- Quality workflow `30750777555` / #493 — PASS
- Recoverable artifact ID `8834500159`
- Recoverable artifact digest `sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49`
- Physically tested debug APK SHA-256 `4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412`
- Signed release artifact ID `8834548293`
- Signed release artifact digest `sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a`
- Signed release APK SHA-256 `ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde`
- Owner acceptance: 2026-08-02

## Base08 fresh re-certification — 2026-08-06

Fresh physical regression testing found and corrected narrow Base08 stabilization issues involving:

- Firestore automatic `messages.timestamp` collection index behavior;
- delivery acknowledgement batch-size mismatch;
- stale online presence repair;
- hardcoded About-screen version display.

Fresh user-reported physical PASS includes Nearby, Chats, text/media, message actions, block/safety, Premium owner flow, Profile Sharing regression, restart/network smoke, mutual two-device Online state, grey delivered double tick, blue read double tick and bidirectional messaging.

PR `#112` restored/cleaned the Base08 working source and merged as `b6837ce2dd90bdc4db87a153089fcaf1cf74a441`.

The final About-screen correction is tracked as PR `#114`; its automated candidate evidence and current focused physical gate are recorded only in `config/official_base_manifest.json` to avoid conflicting duplicate truth.

## Known evidence notes

These are deliberately NOT overstated:

- Batch07 receiver-media pre-download/post-download Premium recovery remains **OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS**.
- Batch08 custom `nearmeu://profile/...` fallback is implemented but was not separately captured as independent physical screenshot evidence; HTTPS warm/cold app links were physically verified.

## Recovery safety

`tool/restore_official_base.ps1` refuses to overwrite uncommitted local work by default. `-Force` is an intentional destructive option and should be used only after the owner chooses to discard local changes.

Normal upgrades to a test phone use a permanent-certificate-matching APK and `adb install -r`. Do not uninstall or clear app data for normal upgrades.

## Production-state safety

Git source recovery does not automatically remove already deployed Firebase functions.

After source recovery run:

```powershell
.\tool\audit_production_state.ps1
```

Unexpected deployed functions are production drift. Do not call the base fully restored until production drift is explained/resolved.

Before any production deployment run:

```powershell
.\tool\verify_deployment_gate.ps1
```

Production deploys from unmerged feature branches are prohibited.

## Recovery promotion rule

The recovery branch moves only after:

- CI PASS;
- permanent signing PASS;
- exact candidate physical acceptance PASS;
- required production actions PASS;
- production-state audit PASS;
- docs/manifest updated;
- owner acceptance recorded.

After promotion, `main`, `stable/official-recoverable-base` and `F:\NearMeU` must represent the same accepted state.

## Future work

No post-Base08 runtime batch is active. Future work remains locked until explicitly unlocked by the owner and must start fresh from the official base rather than from historical experimental branches.
