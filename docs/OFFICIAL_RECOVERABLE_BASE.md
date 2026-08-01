# NearMeU Official Recoverable Base

Last promoted: 2026-08-01

## Current official base

Batch 04 is the accepted runtime/recovery starting point for future NearMeU work.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `d387b5cf8db7d9e792673ada4dd1c1d2958c7aee`
- Tested runtime commit: `f22b36690b7ca65828ce2db809a89abe9931f83e`
- Physical acceptance evidence head: `c98f304f5bd4525315d8f5c6c558e2d0dca98b5d`
- Accepted pull request: `#92`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.7+8`
- Physically tested APK: `NearMeU-Batch-04-v1.0.7-8-Signed.apk`
- Physically tested APK SHA-256: `24e770e3b09cfcb2608b8a8283405cef282f62a4832a3e67fd3a625a2bd2deb8`
- Physically tested artifact ID: `8817336599`
- Physically tested artifact digest: `sha256:6a012c299547e7b32f9f76e5c1ece24e2b4110111bae40289372b1624ccbb39a`
- Final docs-head recoverable artifact ID: `8817642243`
- Final docs-head recoverable artifact digest: `sha256:6bbb921fc7f115bd84aaa3ce1979da65271ea77f4cd129b787120096e3bc10d3`
- Build workflow on tested runtime: `30695802197` / #27 — passed
- Quality workflow on tested runtime: `30695802185` / #422 — passed
- Acceptance-doc build workflow: `30696835582` / #28 — passed
- Acceptance-doc quality workflow: `30696835612` / #423 — passed
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED OFFICIAL RECOVERABLE BASE**

Owner physically tested the signed `1.0.7+8` direct update with no uninstall/data wipe and explicitly accepted the batch on 2026-08-01. Existing login/state remained usable. The focused Batch 04 matrix passed after production deployment of `clearPrivateChat(asia-south1)`.

Accepted Batch 04 behavior adds:

- per-user authoritative Clear Chat cutoff at `clearStates.<uid>.clearedAt`;
- actor-side permanent Clear Chat semantics while the other participant keeps their copy;
- encrypted local rows and referenced local media purged through the clear cutoff;
- cleared chat hidden until strictly newer post-clear activity;
- no old-history resurrection after restart/sync once the clear state is observed;
- Delete for Me no longer recreates an already-expired delivery-cloud document;
- Delete for Everyone remains trusted sender-only within the existing 60-minute window and detaches removed local media/content;
- production `clearPrivateChat` deployed successfully to `nearmeu-e82c7` in `asia-south1`.

Batch 01 tick truth, Batch 02 media reliability and Batch 03 local-first/seven-day delivery-cloud behavior remained regression-safe in the focused acceptance pass.

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
git checkout d387b5cf8db7d9e792673ada4dd1c1d2958c7aee
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

Batch 05 — Identity, account close and reactivation.

Batch 04 is closed and must not be reopened except for a verified regression.
