# Batch 07 — Safe Physical Recovery Test Procedure

Status: physical-acceptance helper for Batch 07 only.

This procedure exists to prove that Premium recovery can rebuild the encrypted local chat database without using **Clear Chat**, **Delete for Me**, **Delete for Everyone**, app-data wipe or uninstall. It must not be used as a normal user workflow.

## Safety rules

- Use the Batch 07 permanently signed **debug/recoverable** APK already accepted for focused testing.
- Keep the same installed app/package: `com.nearmeu.nearmeu`.
- Do **not** uninstall the app.
- Do **not** run `pm clear` or clear app storage.
- Do **not** delete Flutter secure storage; the SQLCipher key must remain available.
- Do **not** use the in-app Clear Chat action to simulate local loss because Clear Chat intentionally purges the owner's recovery copy.
- Force-stop the app before copying, deleting or restoring SQLite files.
- Preserve an emergency copy of every matching database sidecar (`.db`, `-wal`, `-shm`) before the reset.
- This procedure resets local chat database files only. It intentionally does not delete Firebase delivery data, Premium recovery data, secure-storage keys or app-private media folders.

## Preconditions

Before resetting anything, create a small focused test conversation and record what must recover:

1. one fresh Premium text message;
2. one fresh Premium sent media message;
3. for receiver-side media eligibility, note whether the receiver has downloaded the media yet;
4. wait long enough for the production recovery capture/synchronization path to complete;
5. confirm normal chat display before the reset.

Use disposable test content. Do not rely on irreplaceable local-only history as the only copy of important data.

## Step 1 — connect the phone

From the Android platform-tools directory:

```powershell
.\adb.exe devices
```

The target device must show as `device`.

## Step 2 — confirm `run-as` access

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu pwd
```

Expected: a private application-data path is printed. If Android returns that the package is not debuggable or `run-as` is denied, **stop here**. Do not improvise with root or app-data clearing; use another controlled test mechanism instead.

## Step 3 — list the encrypted local chat database files

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'ls -la files/chat_*.db* 2>/dev/null || true'
```

At least one `chat_<uid>.db` should normally appear for a signed-in account that has local chat history.

## Step 4 — force-stop NearMeU

```powershell
.\adb.exe shell am force-stop com.nearmeu.nearmeu
```

Do not relaunch the app until the controlled reset is complete.

## Step 5 — create an emergency in-app backup of the database files

First remove any stale prior test backup and recreate the directory:

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'rm -rf files/batch07_recovery_test_backup && mkdir -p files/batch07_recovery_test_backup'
```

Copy all current encrypted chat database files and sidecars:

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'cp -p files/chat_*.db* files/batch07_recovery_test_backup/ 2>/dev/null || true'
```

Verify the backup exists:

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'ls -la files/batch07_recovery_test_backup/'
```

Do not continue unless the expected database file is visible in the backup directory.

## Step 6 — reset only the local encrypted chat database

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'rm -f files/chat_*.db files/chat_*.db-wal files/chat_*.db-shm'
```

Verify the active database files are gone while the backup remains:

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'echo ACTIVE; ls -la files/chat_*.db* 2>/dev/null || true; echo BACKUP; ls -la files/batch07_recovery_test_backup/'
```

This is the intended simulated local-loss point.

## Step 7 — relaunch NearMeU and allow automatic recovery

Launch the app normally from the phone. Keep the network connected and remain signed into the same account.

Batch 07 recovery is invoked automatically by the global message-delivery lifecycle for each visible private chat. The local SQLCipher database should be recreated using the existing secure-storage key and eligible Premium recovery records should be inserted idempotently.

Check:

- same login remains active;
- the test chat becomes visible;
- eligible Premium text returns;
- eligible sent media returns and opens from the recovery copy;
- no duplicate message IDs appear;
- unrelated Clear/Delete behavior is not simulated by this reset.

## Step 8 — receiver media eligibility boundary

For a fresh receiver-side media message:

1. before the receiver downloads/acknowledges it, confirm it is not treated as that receiver's recoverable media copy;
2. download it on the receiver;
3. allow the trusted acknowledgement/recovery synchronization to complete;
4. repeat the controlled local DB reset for that receiver;
5. confirm the media is now eligible to restore when that receiver is Premium.

This proves the approved rule: receiving a media message is not enough; the receiver must actually download/acknowledge it before the receiver's Premium recovery copy is secured.

## Step 9 — Clear/Delete non-resurrection matrix

Run these as separate focused cases using disposable messages. After each destructive action, repeat the controlled local DB reset and relaunch.

### Clear Chat

- create and recover a disposable message first;
- invoke **Clear Chat** for the testing account;
- repeat the controlled local DB reset;
- the cleared content must **not** return for that account.

### Delete for Me

- create a disposable message;
- invoke **Delete for Me**;
- repeat the controlled local DB reset;
- the deleted message must **not** return for that user.

### Delete for Everyone / Unsend

- create a disposable message within the allowed unsend window;
- invoke **Delete for Everyone**;
- repeat the controlled local DB reset on each participant as needed;
- the message must **not** return for either participant.

## Step 10 — Free-user rejection

With a test account that does not have a valid Premium entitlement, allow the app to reach the same recovery lifecycle. Recovery must not restore Premium recovery content for that Free user. A `premium-required` backend response is an expected controlled refusal, not an app failure.

## Emergency rollback if the recovery test fails

If the reset produces an unexpected result and the original local database must be restored, first force-stop NearMeU:

```powershell
.\adb.exe shell am force-stop com.nearmeu.nearmeu
```

Remove any newly recreated active chat DB files:

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'rm -f files/chat_*.db files/chat_*.db-wal files/chat_*.db-shm'
```

Copy the emergency backup back into the active support directory:

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'cp -p files/batch07_recovery_test_backup/chat_*.db* files/ 2>/dev/null || true'
```

Verify files are present, then launch the app normally:

```powershell
.\adb.exe shell run-as com.nearmeu.nearmeu sh -c 'ls -la files/chat_*.db*'
```

Do not delete the backup directory until Batch 07 focused physical acceptance is complete.

## Acceptance evidence to record

Record only factual results:

```text
Device / Android version:
Installed Batch 07 APK SHA-256:
Same login preserved after local DB reset: PASS / FAIL
Premium text restore: PASS / FAIL
Premium sent-media restore: PASS / FAIL
Receiver before-download non-recovery: PASS / FAIL
Receiver after-download recovery: PASS / FAIL
Clear Chat non-resurrection: PASS / FAIL
Delete for Me non-resurrection: PASS / FAIL
Delete for Everyone non-resurrection: PASS / FAIL
Seven-day delivery-cloud separation regression: PASS / FAIL
Free-user recovery rejection: PASS / FAIL
Unexpected duplicates: YES / NO
Owner decision: ACCEPT / REJECT
```

Batch 07 must not merge until the required focused restore matrix passes and the owner explicitly accepts it.