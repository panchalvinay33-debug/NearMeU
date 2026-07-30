# NearMeU — Recovery Playbook

Use this when a new change breaks build, login, App Check, Nearby, chat, Firebase deployment or Android installation.

## Golden recovery point

- Branch: `stable/official-base-v1-2026-07-30`
- Base merge commit: `a743ffa407c145b3852c547d31f33458e8e839b4`
- Package: `com.nearmeu.nearmeu`

## 1. Recover source safely

Never force-push `main`. Create a recovery branch:

```bash
git fetch origin
git checkout -b recovery/from-official-base origin/stable/official-base-v1-2026-07-30
```

Run all checks, open a PR to `main`, and merge only after the required GitHub checks pass.

## 2. Android signing recovery

The permanent key is not stored in Git. Recover it only from the owner's encrypted backup or GitHub Actions secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`

Certificate identity:

- SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

Reject any APK/AAB with a different certificate unless a documented key migration occurred.

## 3. Device installation recovery

For an update on the permanent signing line:

```powershell
.\adb.exe install -r -t "C:\path\to\app-debug.apk"
```

If Android reports a signature mismatch, stop and verify the APK certificate before uninstalling anything.

A reinstall or app-data reset may create a new App Check debug token. Register it in Firebase App Check and restart the app.

## 4. Google Sign-In and App Check

Confirm:

1. Package is `com.nearmeu.nearmeu`.
2. Firebase Android app contains the permanent SHA-1 and SHA-256.
3. `android/app/google-services.json` matches the intended Firebase project and OAuth client.
4. Google provider is enabled in Firebase Authentication.
5. Debug builds use the App Check debug provider.
6. Release builds use Play Integrity and are tested through a Play testing track.

## 5. Firebase backend recovery

A source rollback does not automatically roll back Firebase.

Before changing production:

1. Export current Firestore data.
2. Record deployed rules, indexes and Functions revisions.
3. Restore/test in staging first.
4. Deploy the last known-good backend from the official base.
5. Verify two-account Nearby, chat, moderation and account deletion behavior.

Use `docs/final/BACKUP_AND_RECOVERY_PLAN.md` for data restoration details.

## 6. Definition of recovered

Recovery is complete only when:

- all required GitHub checks are green
- APK uses the permanent certificate
- Google Sign-In works
- Nearby works with correct App Check configuration
- chat/profile smoke tests pass
- no user data or secrets were exposed
- the new recovery point is documented before replacing the old one

## External records still required

GitHub alone cannot restore signing secret values, Firebase Console settings, App Check tokens, Play Console configuration or live production data. Keep those in secure owner-controlled backups and consoles.