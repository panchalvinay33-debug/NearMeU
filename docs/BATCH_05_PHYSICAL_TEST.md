# Batch 05 Physical Acceptance — Identity, Account Close and Reactivation

Status: **PENDING CI / PRODUCTION DEPLOYMENT / OWNER TEST**

Target version: `1.0.8+9`

Branch: `batch/05-identity-account-close-reactivation`

Base: `c0a734e3dfbbab61b5c1b008df4e3f09bb011556`

This is intentionally a short focused test. Do **not** repeat the full Batch 01–04 chat/media matrices unless a regression is observed.

## Before physical test

Required gates:

- Cloud Functions unit tests PASS.
- Firebase Rules tests PASS.
- Flutter formatter/analyze/tests PASS.
- permanently signed Android artifact PASS.
- package remains `com.nearmeu.nearmeu`.
- permanent signing certificate remains unchanged.
- version is `1.0.8+9`.
- production callables deployed to `nearmeu-e82c7` / `asia-south1`:
  - `ensureIdentityContinuity`;
  - `closeCurrentAccount`;
  - `reactivateCurrentAccount`.

## Focused owner matrix

1. **Direct update**
   - install with Android update / `adb install -r`;
   - do not uninstall or clear app data;
   - existing login/history/local state is preserved before lifecycle test.

2. **Close Account is separate**
   - Settings shows `Sign Out`, `Close Account`, and `Delete Account Permanently` as separate actions;
   - choose `Close Account`;
   - Google reauthentication is requested;
   - after confirmation the account signs out without uninstall/data wipe.

3. **Closed account unavailable**
   - on the other test account/device, the closed identity no longer appears in Nearby/search;
   - new messaging to the closed identity is not allowed by active-user authorization;
   - existing relationship/chat history on the other participant is not destructively deleted.

4. **Same-email reactivation**
   - sign in again with the **same verified Google email**;
   - the app reuses the same Firebase/NearMeU UID, not a duplicate identity;
   - public-profile recreation flow is shown;
   - recreate profile and enter the app successfully.

5. **Continuity after reactivation**
   - existing block relationships remain active in both directions where previously set;
   - uncleared retained local conversation history remains available on the original device;
   - cleared/permanently deleted content does not return;
   - one text-message smoke check works after reactivation.

## Explicitly not part of this batch

- Premium entitlement implementation (Batch 06).
- six-month Premium backup/restore (Batch 07).
- profile deep links (Batch 08).
- voice/video calling (Batch 09/10).

## Acceptance record

Fill only after the exact signed artifact is tested:

```text
Tested runtime commit: PENDING
Build workflow: PENDING
Quality workflow: PENDING
Artifact ID/digest: PENDING
APK SHA-256: PENDING
Permanent signing certificate: PENDING
Production lifecycle deployment: PENDING
Direct-update preservation: PENDING
Close Account: PENDING
Closed-account unavailability: PENDING
Same-email same-UID reactivation: PENDING
Block/history continuity: PENDING
Post-reactivation message smoke: PENDING
Owner decision: PENDING
```
