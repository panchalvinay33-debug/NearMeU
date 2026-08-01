# NearMeU Official Recoverable Base

Last promoted: 2026-08-01

## Current official base

Batch 06 is the accepted runtime/recovery starting point for future NearMeU work.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `2eea2d3fc0583ace77526bae9a918c940e470d24`
- Tested runtime commit: `52fe6a52ad117e9eccb922e535b9d6752af7e695`
- Physical acceptance evidence head: `a626a501db3b1d24573f6002087b2f0d88b16ce3`
- Accepted pull request: `#96`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.9+10`
- Physically tested signed debug APK SHA-256: `2df1a743c313ec8b90b73d52677e2de2360b02c3858e1f9dbd1735c1534a016f`
- Recoverable artifact ID: `8820525497`
- Recoverable artifact digest: `sha256:7a6023c00bc328438efa4135f411286ae98c39485ff2c35f4385697eb78ea4e7`
- Signed release artifact ID: `8820623151`
- Signed release APK SHA-256: `4aac231c92283884cc8af1a5d88ad517c29ae716c7e541d9aa6a8be85d9f4b72`
- Tested-runtime Build workflow: `30706204824` / #40 — passed
- Tested-runtime Quality workflow: `30706204828` / #439 — passed
- Acceptance-head Build workflow: `30709123869` / #44 — passed
- Acceptance-head Quality workflow: `30709123867` / #443 — passed
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED OFFICIAL RECOVERABLE BASE**

Owner physically accepted Batch 06 on 2026-08-01. The focused device test confirmed existing chat/media continuity, Free text messaging, visible Premium locks on voice and photo/video controls, and trusted Premium-required responses after the stale-token recovery fix. The earlier pre-deploy `NOT_FOUND` and stale-token `UNAUTHENTICATED` states were resolved before final acceptance.

Accepted Batch 06 behavior adds:

- one private trusted Premium entitlement model;
- missing/expired entitlement is Free;
- independent `googlePlay` and future `admin` grant evaluation;
- trusted `getMyPremiumEntitlement` callable in `asia-south1`;
- server-side Premium enforcement in `sendPrivateMediaMessage` for outbound photo/video/voice messages;
- Free text messaging and incoming/local media remain available;
- locked outbound media/voice controls remain visible to Free users;
- Premium status is not publicly exposed;
- client retries once with a forced Firebase ID-token refresh on an `UNAUTHENTICATED` entitlement read;
- Google Play purchase verification, six-month Premium recovery and owner-admin grant mutation remain later batches.

## Canonical local workspace

The owner Windows machine canonical project workspace is `F:\NearMeU`.

After each accepted/promoted batch, sync this workspace to promoted `main`; temporary Downloads clones and OLD folders are not the active project.

## Recovery procedure

```powershell
cd "F:\NearMeU"
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
```

Accepted runtime checkpoint:

```powershell
git checkout 2eea2d3fc0583ace77526bae9a918c940e470d24
```

Install only a permanent-certificate-matching APK using update mode (`adb install -r`); never uninstall or wipe for normal upgrades.

## Non-negotiable change control

- All new runtime work starts from this accepted base.
- One runtime batch is active at a time.
- `main` changes through a passing pull request.
- Runtime batches require CI, permanently signed APK, physical-device testing and owner approval.
- `stable/official-recoverable-base` moves only after merged-main acceptance and final documentation are complete.
- Package ID, signing identity and monotonically increasing versionCode remain compatible.

## Next approved batch

Batch 07 — six-month automatic Premium backup and restore.

Batch 06 is closed and must not be reopened except for a verified regression.
