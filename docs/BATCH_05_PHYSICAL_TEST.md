# Batch 05 Physical Acceptance — Identity, Account Close and Reactivation

Status: **OWNER ACCEPTED**

Target version: `1.0.8+9`

Branch: `batch/05-identity-account-close-reactivation`

Base: `c0a734e3dfbbab61b5c1b008df4e3f09bb011556`

This was intentionally a short focused test. The owner did **not** repeat the full Batch 01–04 chat/media matrices because no regression was observed.

## Automated gates

- Cloud Functions unit tests: PASS.
- Firebase Rules tests: PASS.
- Flutter formatter/analyze/tests: PASS.
- Build recoverable base #33 / run `30699307402`: PASS.
- Quality gate #430 / run `30699307401`: PASS.
- package: `com.nearmeu.nearmeu`.
- version: `1.0.8+9`.
- permanent signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`.
- recoverable artifact ID `8818404060`, digest `sha256:70505abc00881695754c70684ae4140ab05224c1c424d242d6cdc9d11e20e94c`.
- tested signed debug APK SHA-256: `c3371eb86c73a090b311c4d42656d8eaf799025aa04cd56da3bc6f51faeaf406`.
- signed release artifact ID `8818505561`, digest `sha256:31b20f4945432c4ab302502f286e041dc603b9fddd047263d00ce100a6148b4f`, release APK SHA-256 `e648ece943692ae4d7bcc083088f8ecbdde91a5c1fb892344076bff0bf8c1966`.

## Focused owner evidence — 2026-08-01

The owner installed the Batch 05 build as an update without uninstall/data wipe and supplied screenshots plus an explicit result summary.

Observed/accepted behavior:

1. Existing chat history remained available after the direct update.
2. After closing the sender account, the receiver saw the identity as `Unavailable user` / offline while the existing conversation remained present.
3. Opening the unavailable identity did not restore a public profile.
4. Attempting to send to the closed identity was refused by authorization; screenshots showed `PERMISSION_DENIED` / `An active NearMeU profile is required.` rather than accepting a message.
5. Signing back in with the same closed account followed the public-profile signup/recreation flow rather than creating a separately usable duplicate active identity.
6. Existing chats were available again after reactivation/profile recreation.
7. Settings visibly showed `Sign Out`, `Close Account`, and `Delete Account Permanently` as three separate actions.
8. The owner explicitly concluded that the Batch 05 work was functioning and accepted the focused result.

The production lifecycle callables were necessarily exercised by the successful Close Account and same-account reactivation flow during this test. The screenshots do not independently document the Firebase CLI deployment transcript, so this acceptance record does not claim a separate CLI-log artifact.

## Explicitly not part of this batch

- Premium entitlement implementation (Batch 06).
- six-month Premium backup/restore (Batch 07).
- profile deep links (Batch 08).
- voice/video calling (Batch 09/10).

## Acceptance record

```text
Tested runtime commit: d2868b97dc931a49f625f4711db4b555fecd34ec
Build workflow: #33 / 30699307402 PASS
Quality workflow: #430 / 30699307401 PASS
Recoverable artifact: 8818404060 / sha256:70505abc00881695754c70684ae4140ab05224c1c424d242d6cdc9d11e20e94c
Signed debug APK SHA-256: c3371eb86c73a090b311c4d42656d8eaf799025aa04cd56da3bc6f51faeaf406
Permanent signing certificate: B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B
Production lifecycle behavior: PASS (exercised physically)
Direct-update/history preservation: PASS
Close Account: PASS
Closed-account neutral unavailability: PASS
Closed-account message authorization refusal: PASS
Same-account reactivation/profile recreation: PASS
Conversation continuity after reactivation: PASS
Account-action separation: PASS
Owner decision: ACCEPTED on 2026-08-01
```
