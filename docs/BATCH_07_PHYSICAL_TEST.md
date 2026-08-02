# Batch 07 Physical Acceptance — Six-Month Premium Backup and Restore

Status: **CI / SIGNED ARTIFACTS / PRODUCTION DEPLOYMENT PASS — OWNER TEST PENDING**

Target version: `1.0.10+11`

Branch: `batch/07-six-month-premium-backup-restore`

Base: `87cdded675716a761372d0b7064d13ec3a8e40f8`

This batch must remain focused. Do not repeat the full Batch 01–06 physical matrices unless a regression is observed.

## Frozen behavior

- Premium recovery is separate from the seven-day delivery cloud.
- New eligible Premium text messages receive per-user recovery retention for up to six calendar months.
- Sent Premium media may be backed up after trusted send acceptance.
- Received media becomes recovery eligible only after that receiver has actually downloaded/acknowledged it.
- Before temporary delivery media is removed after receiver download, eligible Premium sender and receiver recovery copies are synchronously secured; idempotent retries accept an already-existing recovery object even if the temporary source has since been removed.
- Recovery media is copied into a separate per-user storage namespace.
- Premium expiry does not immediately erase an already-valid recovery assignment; recorded expiry controls purge.
- Clear Chat permanently removes that user's recovery copy.
- Delete for Me removes that user's recovery copy even when the seven-day delivery source has already expired.
- Delete for Everyone / unsend removes recovery copies for both participants.
- Restore must never resurrect content at or before the user's authoritative Clear Chat cutoff, even if best-effort recovery cleanup was temporarily deferred.
- Reversible Close Account preserves permitted recovery continuity because the Firebase Auth identity is retained.
- Permanent Account Delete removes the deleted identity's Premium recovery data; a durable retry job handles temporary cleanup failures after Firebase Auth UID deletion.
- Actual voice/video call media is never recorded or backed up.
- Batch 07 does not implement Google Play purchase verification, profile sharing, calling, or owner-admin Premium grants.

## Automated gates

- Premium recovery policy unit tests PASS.
- Cloud Functions bootstrap/load PASS.
- Firebase Storage rules tests PASS, including no client writes to recovery media.
- Existing Firebase Rules tests PASS.
- Flutter formatter/analyze/tests PASS.
- Permanently signed debug/recovery APK PASS.
- Permanently signed release APK PASS.
- Package remains `com.nearmeu.nearmeu`.
- Permanent signing certificate remains unchanged.

Authoritative tested runtime head: `eb15259e2456f9aab547aa474e6d350dba0c429e`.

Automated runtime evidence:

- Build recoverable base APK #63 / run `30715897246` — PASS.
- NearMeU quality gate #464 / run `30715897249` — PASS.
- Recoverable artifact ID `8823448766`, digest `sha256:7b361fb5a0c6cd20c67d24ef5f3645e7520503c654bb0110a9b4402641c163f8`.
- Debug/recoverable APK SHA-256 `fbf1f90abc14b2e19a25d7873ceea39488fc0a250e9d0e89746105441eb8a294`.
- Signed release artifact ID `8823517406`, digest `sha256:de930dd9e0415ba83413255589a1ca3b715f9a4e002dcd74b1ac43d542c8fc0d`.
- Signed release APK SHA-256 `a180d25bd8d0da94529ac6c07041734b2c1197e80fb5038f9f56df4828d008f3`.
- Permanent signing certificate SHA-256 `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`.

Evidence/docs head before deployment: `2d8ca087a15b514b4cb802ba69d4fed0240331da`.

- Build recoverable base APK #64 / run `30733194300` — PASS.
- NearMeU quality gate #465 / run `30733194268` — PASS.

## Production deployment

Owner-provided PowerShell evidence on 2026-08-02 shows Firebase deployment completed successfully for project `nearmeu-e82c7` from the canonical `F:\NearMeU` workspace.

Successfully created/updated production functions shown in the deployment output:

- `capturePremiumRecoveryOnMessageCreate` — created successfully.
- `syncPremiumRecoveryOnMessageUpdate` — created successfully.
- `getMyPremiumRecoveryPage` — created successfully.
- `purgeExpiredPremiumRecovery` — created successfully.
- `deleteMyPremiumRecoveryMessage` — created successfully.
- `purgePremiumRecoveryOnAuthDelete` — created successfully.
- `retryPremiumRecoveryAccountDeletion` — created successfully.
- `acknowledgePrivateMediaDownload` — updated successfully.
- `clearPrivateChat` — updated successfully.
- Firebase Storage Rules `storage.rules` — released successfully.

The terminal ended with `Deploy complete!`.

Deployment is not final owner acceptance until focused physical restore testing passes.

## Focused owner matrix

1. Direct update with `adb install -r`; no uninstall/data wipe.
2. Existing login/chat/media state remains available.
3. Premium eligible text appears in recovery and restores after the test device's local chat copy is intentionally reset through the approved recovery-test procedure.
4. Premium sent media restores from the recovery copy.
5. Receiver media is not backed up before download; after receiver download it becomes recoverable when that receiver is Premium.
6. Clear Chat removes the clearing user's recovery copy and that content does not return after restore.
7. Delete for Me does not return for that user after restore; the backend path is also designed to remain authoritative after the seven-day delivery source expires.
8. Delete for Everyone / unsend does not return for either participant after restore.
9. Seven-day delivery-cloud behavior remains separate and unchanged.
10. Free users cannot invoke Premium restore.
11. Close Account / same-email reactivation continues the permitted uncleared recovery identity; do not repeat the full Batch 05 lifecycle matrix unless a regression appears.
12. Permanent Account Delete cleanup is primarily backend/automated evidence; do not destroy the owner's real test identity solely to prove Batch 07 unless a disposable identity is intentionally used.

## Acceptance record

```text
Tested runtime commit: eb15259e2456f9aab547aa474e6d350dba0c429e
Build workflow: 30715897246 / #63 — PASS
Quality workflow: 30715897249 / #464 — PASS
Recoverable artifact: 8823448766 / sha256:7b361fb5a0c6cd20c67d24ef5f3645e7520503c654bb0110a9b4402641c163f8
Debug APK SHA-256: fbf1f90abc14b2e19a25d7873ceea39488fc0a250e9d0e89746105441eb8a294
Release artifact: 8823517406 / sha256:de930dd9e0415ba83413255589a1ca3b715f9a4e002dcd74b1ac43d542c8fc0d
Release APK SHA-256: a180d25bd8d0da94529ac6c07041734b2c1197e80fb5038f9f56df4828d008f3
Permanent signing certificate: B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B
Evidence-head Build/Quality: 30733194300 / #64 — PASS; 30733194268 / #465 — PASS
Production deployment: PASS — owner PowerShell evidence, 2026-08-02, `Deploy complete!`
Focused physical restore: PENDING
Clear/Delete resurrection checks: PENDING
Owner decision: PENDING
```
