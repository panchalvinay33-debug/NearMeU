# NearMeU Official Recoverable Base

Last promoted: 2026-08-01

## Current official base

This is the only supported recovery and starting point for future NearMeU work.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `9b4b5a03464240c5bfba449a2a0b8ceda1712c1f`
- Accepted feature branch commit: `22af597d63ffedebe701389d671c9f1f345edae7`
- Accepted pull request: `#86`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.4+5`
- Accepted APK: `NearMeU-Batch-01-v1.0.4-5-Signed.apk`
- APK SHA-256: `63866e7e0519a2f00ac81c5df811b26c4ba4ea04e69ab2f61a3c42a06f07fee7`
- Build workflow run: `30683308079` — passed
- Quality workflow run: `30683308083` — passed
- Firebase Functions deployment: passed on 2026-08-01
- Permanent signing certificate SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED OFFICIAL RECOVERABLE BASE**

Physical evidence supplied by the owner confirms:

- the signed APK installed over the existing app with `adb install -r`;
- no uninstall or data wipe was required;
- existing login, encrypted chat history and app state were preserved;
- outgoing messages show a single tick after server acceptance;
- messages show a grey double tick after receiver synchronization;
- messages show a blue double tick after receiver read/open state;
- two-way messaging and replies remain functional;
- the owner explicitly approved this version as the base for all future work.

## Accepted chat-state truth

- Single tick: server accepted/sent.
- Grey double tick: receiver device/app synchronized or observed the message.
- Blue double tick: receiver opened/read the conversation.
- Read-state fallback uses trusted chat `readStates.lastReadAt` so legacy/local-history messages converge safely.
- Delivery listeners restart after app resume and are not limited to the previous 50-chat cap.

## Recovery procedure

```powershell
git fetch origin
git checkout main
git reset --hard origin/main
git clean -fd
```

For the immutable accepted runtime checkpoint:

```powershell
git checkout 9b4b5a03464240c5bfba449a2a0b8ceda1712c1f
```

Build through GitHub Actions workflow **Build recoverable base APK** using the protected permanent signing secrets. Install only a certificate-matching APK:

```powershell
.\adb.exe install -r .\NearMeU-Batch-01-v1.0.4-5-Signed.apk
```

## Non-negotiable change control

- All new runtime work starts from this accepted base.
- One runtime batch is active at a time.
- `main` changes only through a reviewed, passing pull request.
- Runtime batches require CI, a permanently signed APK, physical-device testing and owner approval.
- `stable/official-recoverable-base` moves only after merged-main acceptance and documentation are complete.
- Package ID, signing identity or versionCode compatibility must never be broken.
- Keystores, passwords, App Check debug tokens, test credentials and live user data must never be committed.

## Next approved batch

Batch 02 — photo, video and voice-message reliability.

Batch 02 must start from the promoted recovery branch/main state recorded here. Batch 01 is complete and must not be reopened except for a verified regression.