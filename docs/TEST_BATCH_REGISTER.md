# NearMeU V1 Launch Verification Register

Last updated: 2026-08-08

This register tracks only the current V1 launch stabilization. Numbered future batches are not active project instructions.

## Verified current state

| Area | Status | Evidence/requirement |
|---|---|---|
| Firebase cleanup | PASS | later-feature Firestore/Storage residue removed after backup |
| Firestore rules | PASS | V1 rules deployed |
| Firestore indexes | PASS | V1 indexes deployed |
| Storage rules | PASS | V1 rules deployed |
| Cloud Functions | PASS | V1 set deployed; later-feature Functions removed |
| Cloud Functions tests | PASS | 43 passed, 0 failed |
| Duplicate chat audit | PASS | no duplicate canonical chat pairs |
| Physical duplicate chat check | PASS | duplicate chat rows no longer reproduced |
| Owner admin | PASS | owner admin flag restored/verified |

## Open launch verification

| Gate | Status | Acceptance requirement |
|---|---|---|
| Delivery/read/unread truth | OPEN | fresh two-account/device tests prove pending, accepted, delivered, read and unread behavior |
| Identity deactivation/reactivation | OPEN | same account returns to same identity/profile/chats without duplicate behavior or onboarding |
| Public/private profile consistency | OPEN | legacy users classified and safely migrated; malformed records handled explicitly |
| Presence consistency | OPEN | Nearby, Chats and Chat screen agree; online only while app is foreground/resumed |

## Fresh message acceptance scenarios

Run with newly sent messages after backend alignment:

- both users online;
- receiver in foreground;
- receiver backgrounded;
- receiver offline then reconnects;
- receiver opens the chat;
- sender/receiver app restart;
- rapid messages;
- network interruption/recovery.

Do not rewrite historical delivery/read values solely to make old records match the new acceptance semantics.

## Identity acceptance scenarios

- deactivate a current account without deleting its Firebase identity;
- verify removal from Nearby/current availability;
- verify counterpart existing chat shows a deactivated-account state;
- sign in again with the same account;
- verify same identity, same profile and same uncleared chats;
- verify onboarding is skipped for the preserved complete profile;
- verify profile fields remain unchanged unless edited explicitly.

## Profile consistency acceptance scenarios

- audit every `users/{uid}` against `privateProfiles/{uid}`;
- separate current-schema users from legacy users and malformed/empty records;
- move safely recoverable private fields out of legacy public profiles;
- do not invent missing personal data;
- verify current-schema public documents no longer contain private email/exact-location fields;
- verify login/onboarding routing for migrated accounts.

## Presence acceptance scenarios

Verify the same other user simultaneously from Nearby, Chats and Chat screen:

- app foreground/resumed -> online/green dot everywhere;
- app background/minimized -> offline/last-seen everywhere;
- app reopened -> online everywhere;
- network loss/process termination -> stale online state expires safely;
- sign-out -> offline;
- last activity text uses the same source and does not contradict another screen.

## Final V1 release record

Complete only when all open gates pass:

```text
Launch branch:
Final commit:
APK/AAB filename:
APK/AAB SHA-256:
Signing certificate identity:
Workflow run(s):
Test device(s):
Android version(s):
Test accounts:
Flutter tests:
Firebase rules tests:
Cloud Functions tests:
Physical messaging tests:
Presence tests:
Identity/reactivation tests:
Profile migration audit:
Known launch limitations:
Owner decision:
Launch accepted: YES/NO
```

Anything outside the current V1 launch requirements is deferred to V2 after V1 launch.