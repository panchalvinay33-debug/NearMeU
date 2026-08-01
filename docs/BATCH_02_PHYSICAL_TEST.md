# Batch 02 — Physical Acceptance Checklist

Status: required before Batch 02 merge or recovery-base promotion.

Target build: NearMeU `1.0.5+6`
Package: `com.nearmeu.nearmeu`
Accepted previous base: `1.0.4+5`
Branch: `batch/02-media-reliability`
PR: #88

## Hard stop rules

Do not uninstall the accepted app to make the update work.

Stop Batch 02 immediately if any of these occurs:

- `INSTALL_FAILED_UPDATE_INCOMPATIBLE` — signing identity mismatch.
- `INSTALL_FAILED_VERSION_DOWNGRADE` — versionCode is not monotonic.
- login disappears after update.
- encrypted local chat history disappears after update.
- existing app state is wiped.
- duplicate media messages appear after retry/resume.

A failed build/test stays on Batch 02. Do not merge and do not move `stable/official-recoverable-base`.

## 1. Direct update gate

On each physical phone:

```powershell
cd "$env:USERPROFILE\Downloads\platform-tools"
.\adb.exe devices
.\adb.exe install -r "$env:USERPROFILE\Downloads\NearMeU-Batch-02-v1.0.5-6-Signed.apk"
```

Expected result:

```text
Performing Streamed Install
Success
```

Verify installed version when needed:

```powershell
.\adb.exe shell dumpsys package com.nearmeu.nearmeu | Select-String "versionName|versionCode"
```

Expected:

```text
versionName=1.0.5
versionCode=6
```

After update confirm before media testing:

- existing account is still signed in;
- old text chat/history is visible;
- accepted sent/delivered/read tick behavior still works;
- no app-data clear or uninstall was required.

## 2. Photo acceptance

Use one fresh unique photo.

Sender:

1. Send photo.
2. Confirm only one message bubble is created.
3. Background and resume app once after send.

Receiver:

1. Receive the photo message.
2. Tap download.
3. Open the photo.
4. Force-close NearMeU.
5. Reopen NearMeU and open the same chat.
6. Open the same photo again without requiring a new cloud download.

Pass only if the photo remains valid locally after restart and no duplicate appears.

## 3. Video acceptance

Use one short unique video.

Sender:

1. Send video.
2. Confirm exactly one message bubble.
3. Background/resume once after send.

Receiver:

1. Download video.
2. Play video.
3. Confirm thumbnail/preview is usable.
4. Force-close and reopen NearMeU.
5. Open same chat and play same video again.

Pass only if the local video remains usable after restart and no duplicate appears.

## 4. Voice acceptance

Record a fresh voice message longer than one second.

Sender:

1. Send voice message.
2. Confirm exactly one voice bubble.
3. Background/resume once after send.

Receiver:

1. Tap voice message to download/play.
2. Confirm audio plays correctly.
3. Force-close and reopen NearMeU.
4. Open same chat and play the same voice message again.

Pass only if the local audio remains usable after restart and no duplicate appears.

## 5. Offline / reconnect acceptance

Use a new media message.

1. Put receiver offline.
2. Sender sends media.
3. Bring receiver online and reopen/resume NearMeU.
4. Confirm message appears normally.
5. Download/open/play it.

For an ambiguous sender-side confirmation scenario, resume NearMeU after connectivity returns. The pending media outbox must reconcile without creating a second message.

## 6. Download retry acceptance

For photo/video/voice, temporarily interrupt connectivity while starting a download.

Expected:

- incomplete `.part` data is not treated as valid media;
- retry is possible after connectivity returns;
- photo/video tile shows an explicit retry state after failure;
- voice control shows an explicit retry state after failure;
- successful retry opens/plays correctly;
- no duplicate chat message is created.

## 7. Final regression

After all media tests:

- normal text send/receive still works;
- grey delivered and blue read ticks still work;
- app restart preserves login/history;
- photo opens;
- video plays;
- voice plays;
- no duplicate media messages;
- no crash during background/resume.

## Evidence to record after PASS

```text
Batch: 02
Version: 1.0.5+6
Final branch commit:
Signed APK filename:
APK SHA-256:
Build workflow run:
Quality workflow run:
Phone 1 model / Android:
Phone 2 model / Android:
Direct update: PASS/FAIL
Login/history preserved: PASS/FAIL
Photo: PASS/FAIL
Video: PASS/FAIL
Voice: PASS/FAIL
Offline/reconnect: PASS/FAIL
Interrupted download retry: PASS/FAIL
No duplicates: PASS/FAIL
Text/tick regression: PASS/FAIL
Owner decision: ACCEPTED / TEST_FAILED
```

Only after every required gate passes may PR #88 be moved from draft to ready, merged, documented, and promoted as the official recovery base.
