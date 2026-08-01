# NearMeU Official Recoverable Base

Last promoted: 2026-08-01

## Current official base

Batch 03 is the accepted runtime/recovery starting point for future NearMeU work.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `e98bd0ebe86dad1f689723a9e96f35095a015a7b`
- Final Batch 03 evidence head: `075c7e6d4abb05f40e4ed8b116aa20eddecf2c09`
- Tested runtime commit: `72e25450a2df38cf44183d994a13f6acd61369e5`
- Accepted pull request: `#90`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.6+7`
- Accepted APK: `NearMeU-Batch-03-v1.0.6-7-Signed.apk`
- APK SHA-256: `a5e1c9b9a89e83b39023b95a8b1c8c2fd8c33e8cd120ad63c55a68cfe8c7d024`
- Final artifact ID: `8816552470`
- Final artifact digest: `sha256:ce88dcebc0c38bcae77e32596f22a37d54a2f11a5ef84176282c624c8789e7d1`
- Build workflow: `30693343758` / #25 — passed
- Quality workflow: `30693343752` / #418 — passed
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED OFFICIAL RECOVERABLE BASE**

Owner physical testing confirmed the signed `1.0.6+7` direct update is working with no uninstall/data wipe. Login, existing history and app state were preserved; offline/restart local history and downloaded photo/video/voice reuse passed; Batch 01 tick truth and Batch 02 media behavior remained regression-safe.

Accepted Batch 03 behavior adds:

- local-first chat/media persistence after temporary cloud delivery copies expire;
- explicit `cloudExpiresAt` handling;
- valid local media remains usable independently of cloud expiry;
- expired remote media is not advertised as downloadable;
- orphan-safe scheduled purge for private Storage media;
- Storage deletion failure defers Firestore message deletion for retry;
- production retention functions successfully deployed to `nearmeu-e82c7` in `asia-south1`:
  - `stampPrivateMessageRetention`;
  - `purgeExpiredPrivateMessages`.

## Canonical local workspace

The owner Windows machine canonical project workspace is `F:\NearMeU`.

- Development, Git operations, Firebase deployment and recovery synchronization use `F:\NearMeU` unless the owner explicitly changes the path.
- Temporary Downloads clones are not the long-term project base.
- After each accepted/promoted batch, `F:\NearMeU` must be synchronized to the promoted `main` / `stable/official-recoverable-base` state.
- `F:\NearMeU-OLD` and dated folders are backups only.

## Recovery procedure

From `F:\NearMeU`:

```powershell
cd "F:\NearMeU"
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
```

Accepted runtime checkpoint:

```powershell
git checkout e98bd0ebe86dad1f689723a9e96f35095a015a7b
```

Install only a permanent-certificate-matching APK using update mode (`adb install -r`); never uninstall or wipe for normal upgrades.

## Non-negotiable change control

- All new runtime work starts from this accepted base.
- One runtime batch is active at a time.
- `main` changes through a passing pull request.
- Runtime batches require CI, permanently signed APK, physical-device testing and owner approval.
- `stable/official-recoverable-base` moves only after merged-main acceptance and final documentation are complete.
- Package ID, signing identity and monotonically increasing versionCode must remain compatible.
- Keystores, passwords, App Check tokens, test credentials and live user data must never be committed.

## Next approved batch

Batch 04 — Clear Chat and deletion semantics.

Batch 03 is closed and must not be reopened except for a verified regression.
