# NearMeU Official Recoverable Base

Last promoted: pending final Batch 07 documentation merge on 2026-08-02

## Current accepted base

Batch 07 is the accepted runtime/recovery starting point for future NearMeU work.

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted merged runtime commit: `db48338e6528b61e1e486d6d158c9d62e641c977`
- Tested runtime commit: `5ae058122d927c7e35257fb80ca5fa879f14b784`
- Accepted pull request: `#98`
- Android application ID: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- App version: `1.0.10+11`
- Physically tested signed debug APK SHA-256: `2af784329a1594a761877110c671508b19f8cd1cc2542d9079cc46a7b80025d1`
- Recoverable artifact ID: `8833110504`
- Recoverable artifact digest: `sha256:75892030fb34647b64b89fd6f1ac3a94b48acac6bf24217eb63b69a5feb5c6fc`
- Signed release artifact ID: `8833182373`
- Signed release artifact digest: `sha256:4bc19b26851ab9349a578fb9fe64b6d609af16e0ff9da2432194a25106e4b403`
- Signed release APK SHA-256: `19a100dcfa64dc00bb71e918452d8c70d902d2b42ced8e72e6ef04eef5568442`
- Build workflow: `30746260270` / #79 — PASS
- Quality workflow: `30746260318` / #480 — PASS
- Permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

## Owner acceptance

Status: **ACCEPTED** on 2026-08-02.

Accepted physical/backend evidence includes direct-update continuity, Premium text restore, Premium sent-photo restore, Clear Chat no-resurrection, Delete-for-Me no-resurrection, Unsend/Delete-for-Everyone no-resurrection, cross-account Clear Chat isolation, seven-day delivery-cloud regression and backend-enforced Free-user Premium recovery rejection.

Known evidence gap: receiver-media pre-download/post-download recovery eligibility remains **OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS**.

## Canonical local workspace

Owner workspace: `F:\NearMeU`.

After the final documentation merge and recovery-branch promotion, synchronize this workspace to promoted `main` before Batch 08 starts.

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
git checkout 5ae058122d927c7e35257fb80ca5fa879f14b784
```

For merged-main Batch 07 runtime:

```powershell
git checkout db48338e6528b61e1e486d6d158c9d62e641c977
```

Install only an APK signed by the permanent matching certificate and use update mode (`adb install -r`). Do not uninstall or wipe normal test installations.

## Batch 07 accepted behavior

- separate per-user six-month Premium recovery store;
- Premium entitlement is trusted server-side truth;
- sent Premium media can be recovered;
- received media recovery is implemented to require download acknowledgement;
- restore is idempotent into encrypted local chat storage;
- Clear Chat blocks/purges that user's recovery history;
- Delete for Me purges that user's recovery copy;
- Unsend/Delete for Everyone purges both participants' recovery copies;
- seven-day delivery cloud remains separate;
- permanent Auth deletion has recovery cleanup/retry handling;
- call audio/video is never backed up.

## Next approved batch

Batch 08 — profile sharing and deep-link recovery.

Batch 07 is closed after the final docs merge, recovery-branch fast-forward and `F:\NearMeU` sync complete.
