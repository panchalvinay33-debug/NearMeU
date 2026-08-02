# Batch 07 Physical Acceptance — Six-Month Premium Backup and Restore

Status: **OWNER ACCEPTED — ONE RECEIVER-MEDIA CHECK DEFERRED**

Date: 2026-08-02
Version: `1.0.10+11`
Runtime branch: `batch/07-six-month-premium-backup-restore`
Base: `87cdded675716a761372d0b7064d13ec3a8e40f8`
Accepted tested runtime head: `5ae058122d927c7e35257fb80ca5fa879f14b784`
Merged main runtime: `db48338e6528b61e1e486d6d158c9d62e641c977`
PR: `#98`

## Final CI and artifacts

- Build recoverable base APK #79 / run `30746260270` — PASS.
- NearMeU quality gate #480 / run `30746260318` — PASS.
- Recoverable artifact ID `8833110504`.
- Recoverable artifact digest `sha256:75892030fb34647b64b89fd6f1ac3a94b48acac6bf24217eb63b69a5feb5c6fc`.
- Physically tested signed debug APK SHA-256 `2af784329a1594a761877110c671508b19f8cd1cc2542d9079cc46a7b80025d1`.
- Signed release artifact ID `8833182373`.
- Signed release artifact digest `sha256:4bc19b26851ab9349a578fb9fe64b6d609af16e0ff9da2432194a25106e4b403`.
- Signed release APK SHA-256 `19a100dcfa64dc00bb71e918452d8c70d902d2b42ced8e72e6ef04eef5568442`.
- Android package `com.nearmeu.nearmeu` unchanged.
- Permanent signing certificate unchanged: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`.

## Production deployment

Batch 07 recovery functions and Storage Rules were deployed to Firebase project `nearmeu-e82c7` on 2026-08-02. The owner-provided terminal evidence ended with `Deploy complete!`. Later preview fixes were physically verified in the accepted build: Clear Chat and Delete-for-Me no longer leave stale chat previews.

## Accepted behavior

- Separate per-user Premium recovery store independent of seven-day delivery cloud.
- Eligible Premium recovery retention up to six calendar months using recorded expiry.
- Sent Premium media recovery supported.
- Received media recovery assignment is designed to occur only after receiver download acknowledgement.
- Automatic restore into encrypted local chat store is idempotent.
- Clear Chat permanently removes that user's recoverable copy and authoritative cutoff blocks resurrection.
- Delete for Me removes that user's recovery copy.
- Delete for Everyone / Unsend removes both users' recovery copies.
- Free users are rejected by the trusted Premium recovery callable.
- Close Account keeps the same Auth identity and permitted recovery continuity; permanent Auth deletion has cleanup/retry handling.
- Actual call audio/video is never backed up.

## Final focused owner matrix

1. Direct update with `adb install -r`, no uninstall/data wipe — **PASS**.
2. Existing login/chats/media preserved — **PASS**.
3. Temporary trusted Premium entitlement enabled focused Premium testing — **PASS**.
4. Premium eligible text restored after approved local DB reset — **PASS**.
5. Premium sent photo restored and rendered — **PASS**.
6. Receiver media pre-download vs post-download recovery eligibility — **OWNER-DEFERRED; NOT PHYSICALLY VERIFIED; NOT CLAIMED AS PASS**.
7. Clear Chat UI semantics and stale-preview fix — **PASS**.
8. Clear Chat non-resurrection after approved DB reset — **PASS**.
9. Delete for Me preview semantics — **PASS**.
10. Delete for Me non-resurrection after approved DB reset — **PASS**.
11. Delete for Everyone / Unsend UI and preview semantics — **PASS**.
12. Unsend original content does not resurrect after approved DB reset — **PASS**.
13. Cross-account Clear Chat isolation — **PASS**; clearing admin-side history did not clear the other participant's copy.
14. Seven-day delivery-cloud quick regression — **PASS**; fresh photo delivery/rendering remained functional.
15. Free-user Premium restore authorization — **BACKEND-ENFORCED PASS**; `getMyPremiumRecoveryPage` calls trusted entitlement evaluation and rejects non-Premium users with `premium-required`.
16. Permanent Account Delete — backend/automated cleanup evidence accepted; owner's real identity was not destroyed solely for this batch.

## Important test note

The approved DB-reset procedure removed only the active encrypted chat DB while retaining the test backup folder and app identity. App uninstall, app-data clear, secure-storage deletion and destructive account deletion were not used as recovery simulations.

## Owner decision

**ACCEPTED on 2026-08-02.**

The owner accepted Batch 07 with the receiver-media pre/post-download physical check explicitly deferred. This deferred check remains a known evidence gap and must not be rewritten as a PASS. Batch 08 may start only after documentation closeout, recovery-branch promotion and canonical local workspace sync are complete.
