# NearMeU Official Recoverable Base

Last promoted: 2026-08-01

## Current official base

This is the supported recovery and starting point for future NearMeU runtime work after the Batch 02 documentation merge and recovery-branch promotion.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `d7a8c800d48beb7f646fb4d76d0afd7fbfeafa56`
- Accepted feature branch commit: `bbed8998040099202e50e26c62782a04b6b9fe04`
- Accepted pull request: `#88`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.5+6`
- Accepted APK: `NearMeU-Batch-02-v1.0.5-6-Signed.apk`
- APK SHA-256: `b355c854f210aea3787b937a46ab6714f60e18f7acf471779a4daf2655f43d76`
- Artifact ID: `8814680642`
- Artifact digest: `sha256:929f66eab59f188bd57f4a8ab586f9bacea2185093041b631e1b8df4f0960bd6`
- Build workflow run: `30687614764` / #20 — passed
- Quality workflow run: `30687614766` / #411 — passed
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED OFFICIAL RECOVERABLE BASE**

Physical owner testing confirmed the Batch 02 build is working. Direct-update compatibility remains mandatory: no uninstall/data wipe, existing login/history/app state must survive, and package/signing/versionCode compatibility must remain intact.

Accepted runtime behavior now includes:

- Batch 01 sent/delivered/read tick truth;
- photo send/download/open/restart reliability;
- video send/download/play/restart reliability;
- voice send/download/play/restart reliability;
- integrity checks for local media before reuse;
- cleanup of corrupt/partial media;
- explicit retry states after failed downloads;
- pending private-media outbox recovery on authentication and app resume;
- idempotent/verified voice confirmation that avoids false failure and duplicate recovery.

## Recovery procedure

```powershell
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
```

Accepted merged runtime checkpoint:

```powershell
git checkout d7a8c800d48beb7f646fb4d76d0afd7fbfeafa56
```

Install only a certificate-matching APK using update mode:

```powershell
.\adb.exe install -r .\NearMeU-Batch-02-v1.0.5-6-Signed.apk
```

## Non-negotiable change control

- All new runtime work starts from this accepted base.
- One runtime batch is active at a time.
- `main` changes through a passing pull request.
- Runtime batches require CI, a permanently signed APK, physical-device testing and owner approval.
- `stable/official-recoverable-base` moves only after merged-main acceptance and documentation are complete.
- Package ID, signing identity and monotonically increasing versionCode must never be broken.
- Keystores, passwords, App Check tokens, test credentials and live user data must never be committed.

## Next approved batch

Batch 03 — local-first persistence and seven-day delivery cloud.

Batch 02 is closed and must not be reopened except for a verified regression.