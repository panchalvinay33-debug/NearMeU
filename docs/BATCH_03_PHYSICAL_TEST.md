# Batch 03 Physical Acceptance — Local-first + Seven-day Delivery Cloud

Use only the permanently signed Batch 03 APK. Install with `adb install -r`; do not uninstall or clear app data.

## A. Direct-update safety

Pass only if:

- package remains `com.nearmeu.nearmeu`;
- existing login remains signed in;
- existing encrypted chats remain visible;
- previously downloaded Batch 02 photo/video/voice files still open/play;
- no app-data reset is required.

## B. Local-first text persistence

1. With both devices online, exchange several text messages.
2. Confirm normal sent/delivered/read ticks.
3. Close and reopen both apps.
4. Disable network on one device and reopen the same chat.

Pass only if the already synchronized text history remains visible from encrypted local storage while offline.

## C. Local media survives cloud unavailability

For one photo, one short video and one voice message:

1. Receiver downloads/opens or plays it while cloud delivery copy is available.
2. Restart receiver app.
3. Reopen while offline.

Pass only if downloaded local media still opens/plays. Cloud availability must not be required once a valid local file exists.

## D. Expired cloud media truth

Automated tests prove the exact `cloudExpiresAt` boundary. For a controlled backend retention test, use a non-production test message whose expiry is already due; do not alter real user history merely to accelerate testing.

Pass only if:

- media not downloaded before expiry is no longer offered as a valid download;
- UI does not repeatedly attempt a known-expired cloud object;
- a previously downloaded local copy remains usable;
- no valid local file is deleted by cloud cleanup.

## E. Backend orphan prevention

Deploy the updated retention functions before final acceptance. Use controlled test media and verify:

- valid private media object is deleted before its Firestore delivery message is purged;
- a Storage deletion failure does not delete the Firestore message in that same pass;
- an unexpected/out-of-scope Storage path is refused rather than deleted;
- a later successful scheduled retry can complete cleanup.

## F. Regression checks

One short pass only:

- text: single tick -> grey double tick -> blue double tick;
- photo send/download/open;
- video send/download/play;
- voice send/download/play;
- app background/resume does not duplicate media messages.

## Failure conditions

Batch 03 fails immediately if any of these occur:

- direct update requires uninstall/data wipe;
- login or encrypted history disappears;
- locally downloaded media disappears solely because cloud retention expired;
- expired remote media is presented as downloadable when no local copy exists;
- cleanup can delete a Firestore media message while its Storage deletion failed;
- package/signing/versionCode compatibility breaks.

## Evidence to record

- final branch commit;
- signed APK filename + SHA-256;
- build + quality workflow IDs;
- Firebase retention deployment result;
- devices used;
- direct-update result;
- sections A-F pass/fail;
- owner decision.
