# Batch 07 Physical Acceptance — Six-Month Premium Backup and Restore

Status: **IN PROGRESS — IMPLEMENTATION / CI / PRODUCTION / OWNER TEST PENDING**

Target version: `1.0.10+11`

Branch: `batch/07-six-month-premium-backup-restore`

Base: `87cdded675716a761372d0b7064d13ec3a8e40f8`

This batch must remain focused. Do not repeat the full Batch 01–06 physical matrices unless a regression is observed.

## Frozen behavior

- Premium recovery is separate from the seven-day delivery cloud.
- New eligible Premium text messages receive per-user recovery retention for up to six calendar months.
- Sent Premium media may be backed up after trusted send acceptance.
- Received media becomes recovery eligible only after that receiver has actually downloaded/acknowledged it.
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

## Required production deployment

Expected Batch 07 backend/runtime deployment includes:

- `capturePremiumRecoveryOnMessageCreate`
- `syncPremiumRecoveryOnMessageUpdate`
- `getMyPremiumRecoveryPage`
- `purgeExpiredPremiumRecovery`
- `deleteMyPremiumRecoveryMessage`
- `purgePremiumRecoveryOnAuthDelete`
- `retryPremiumRecoveryAccountDeletion`
- updated `clearPrivateChat`
- updated Storage Rules for owner-only recovery-media reads.

Deployment is not evidence of acceptance until focused physical restore testing passes.

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
Tested runtime commit: PENDING
Build workflow: PENDING
Quality workflow: PENDING
Recoverable artifact: PENDING
Debug APK SHA-256: PENDING
Release artifact: PENDING
Release APK SHA-256: PENDING
Permanent signing certificate: PENDING
Production deployment: PENDING
Focused physical restore: PENDING
Clear/Delete resurrection checks: PENDING
Owner decision: PENDING
```
