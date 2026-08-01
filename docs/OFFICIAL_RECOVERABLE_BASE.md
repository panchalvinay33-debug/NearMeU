# NearMeU Official Recoverable Base

Last promoted: 2026-08-01

## Current official base

Batch 05 is the accepted runtime/recovery starting point for future NearMeU work.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `44143f612cbf8b7adf6d591abe74aac2c6397704`
- Tested runtime commit: `d2868b97dc931a49f625f4711db4b555fecd34ec`
- Physical acceptance evidence head: `311b8a364d9701c6424cad719c5a5aa50a7c0bf6`
- Accepted pull request: `#94`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.8+9`
- Physically tested signed debug APK SHA-256: `c3371eb86c73a090b311c4d42656d8eaf799025aa04cd56da3bc6f51faeaf406`
- Recoverable artifact ID: `8818404060`
- Recoverable artifact digest: `sha256:70505abc00881695754c70684ae4140ab05224c1c424d242d6cdc9d11e20e94c`
- Signed release artifact ID: `8818505561`
- Signed release APK SHA-256: `e648ece943692ae4d7bcc083088f8ecbdde91a5c1fb892344076bff0bf8c1966`
- Tested-runtime Build workflow: `30699307402` / #33 — passed
- Tested-runtime Quality workflow: `30699307401` / #430 — passed
- Acceptance-head Build workflow: `30700741431` / #36 — passed
- Acceptance-head Quality workflow: `30700741441` / #433 — passed
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED OFFICIAL RECOVERABLE BASE**

Owner physically accepted Batch 05 on 2026-08-01 after focused two-account testing. Evidence showed existing chat history preserved, closed identity displayed as `Unavailable user`, messaging to a closed account refused, same-account reactivation routed through public-profile recreation, chat continuity returned after reactivation, and Sign Out / Close Account / Delete Account Permanently remained distinct.

Accepted Batch 05 behavior adds:

- one verified email maps to one continuing NearMeU identity;
- reversible Close Account separate from Sign Out and permanent deletion;
- Close Account removes the active public profile from discovery/authorization while preserving identity continuity and block subcollections;
- exact private location fields and registered device tokens are cleared as part of account closure cleanup;
- closed account is unavailable to new messaging and public profile access;
- same verified account reactivation returns to profile recreation without creating a second active identity;
- uncleared retained chat continuity survives close/reactivation on the tested device;
- owner administrator self-close remains blocked;
- Batch 01–04 accepted behavior remains the inherited base.

The production lifecycle callables exercised by the accepted flow are `ensureIdentityContinuity`, `closeCurrentAccount`, and `reactivateCurrentAccount` in `asia-south1`.

## Canonical local workspace

The owner Windows machine canonical project workspace is `F:\NearMeU`.

- Development, Git operations, Firebase deployment and recovery synchronization use `F:\NearMeU` unless explicitly changed.
- Temporary Downloads clones are not the long-term project base.
- After each accepted/promoted batch, `F:\NearMeU` must be synchronized to promoted `main` / `stable/official-recoverable-base`.
- `F:\NearMeU-OLD` and dated folders are backups only.

## Recovery procedure

```powershell
cd "F:\NearMeU"
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
```

Accepted runtime checkpoint:

```powershell
git checkout 44143f612cbf8b7adf6d591abe74aac2c6397704
```

Install only a permanent-certificate-matching APK using update mode (`adb install -r`); never uninstall or wipe for normal upgrades.

## Non-negotiable change control

- All new runtime work starts from this accepted base.
- One runtime batch is active at a time.
- `main` changes through a passing pull request.
- Runtime batches require CI, permanently signed APK, physical-device testing and owner approval.
- `stable/official-recoverable-base` moves only after merged-main acceptance and final documentation are complete.
- Package ID, signing identity and monotonically increasing versionCode remain compatible.
- Keystores, passwords, App Check tokens, test credentials and live user data must never be committed.

## Next approved batch

Batch 06 — Premium entitlement foundation.

Batch 05 is closed and must not be reopened except for a verified regression.
