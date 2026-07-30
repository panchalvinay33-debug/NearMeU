# NearMeU — Recovery Playbook

Use this document when a new change breaks build, login, App Check, Nearby, chat, Firebase deployment or Android installation.

## Golden recovery point

- Commit: `48a290c58a14a71174b921832e516b568b06ba48`
- Stable branch: `stable/permanent-signed-2026-07-30`
- Release branch: `release/permanent-signed-v1`
- Package: `com.nearmeu.nearmeu`

Do not guess during recovery. First identify whether the failure is source code, Firebase configuration, signing, App Check, deployment or device state.

## 1. Source-code rollback

Create a recovery branch instead of rewriting `main` immediately:

```bash
git fetch origin
git checkout -b recovery/from-permanent-baseline origin/stable/permanent-signed-2026-07-30
```

Run the complete local checks and open a PR to `main`. Never force-push `main` to an older commit unless there is a confirmed emergency and a separate backup of the current head exists.

## 2. Android signing recovery

The permanent key is not stored in Git. Recover it only from the owner's secure backup or GitHub Actions secrets.

Required secret names:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`

Certificate identity:

- SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

Reject any APK/AAB whose certificate differs from this identity unless a formally documented key migration has occurred.

## 3. Device installation recovery

For an update already on the permanent signing line:

```powershell
.\adb.exe install -r -t "C:\path\to\app-debug.apk"
```

If Android reports signature mismatch, stop. Confirm the APK certificate before uninstalling anything. A mismatch means the APK was signed with another key.

A reinstall or app-data reset can generate a new Firebase App Check debug token. Register the new token in Firebase App Check for debug testing, then restart the app.

## 4. Google Sign-In recovery

Confirm all of the following:

1. Package is `com.nearmeu.nearmeu`.
2. Firebase Android app contains the permanent SHA-1 and SHA-256.
3. The current `android/app/google-services.json` contains the OAuth client for certificate hash `7fb64fdb90b7d127575fa4f9ee692aecbe8e7e55`.
4. Google provider remains enabled in Firebase Authentication.
5. Rebuild after any `google-services.json` change.

## 5. App Check recovery

Debug build:

- Uses App Check debug provider.
- Register the device/install debug token in Firebase Console.
- Restart the app after registration.

Release build:

- Uses Play Integrity.
- Test only through a Play testing track before enabling enforcement.
- Do not assume a sideloaded release APK will satisfy Play Integrity.

## 6. Firebase backend recovery

A source rollback does not automatically roll back Firebase.

Before changing production:

1. Export current Firestore state.
2. Record current deployed rules, indexes and Functions revision.
3. Test restoration in staging.
4. Deploy the last known-good rules/functions from the stable commit.
5. Verify two-account access, Nearby, chat and moderation behavior.

Use `docs/final/BACKUP_AND_RECOVERY_PLAN.md` for full data restoration procedure.

## 7. Failure triage order

1. Check GitHub Actions conclusion and exact failed step.
2. Compare current head with the golden baseline.
3. Check signing certificate.
4. Check Firebase package/SHA/OAuth configuration.
5. Check App Check provider/token/enforcement.
6. Check whether backend changes were actually deployed.
7. Check physical-device logs and reproduce with a second account/device.

## 8. Definition of recovered

Recovery is complete only when:

- CI is green.
- APK uses the permanent certificate.
- Google Sign-In works.
- Nearby works with correct App Check configuration.
- Chat and profile smoke tests pass.
- No user data or secrets were exposed.
- The new recovery point is documented before old backups are removed.
