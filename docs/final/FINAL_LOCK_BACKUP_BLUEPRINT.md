# NearMeU — Final Lock, Backup, Roadmap and Blueprint

## Verified working baseline

- Source commit: `48a290c58a14a71174b921832e516b568b06ba48`
- Permanent Android signing is restored from GitHub Actions secrets.
- Permanent certificate SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- Permanent certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`
- GitHub Actions run `30514551494` passed Flutter, Firebase rules and Cloud Functions checks and produced permanently signed debug and release APK artifacts.
- Physical Android verification completed for install, Google sign-in, App Check debug registration and Nearby loading.

## Source-control locks

1. `main` remains the only source-of-truth development branch.
2. Never push untested application changes directly to `main`; use a focused branch and pull request.
3. Require a green `NearMeU quality gate` before merge.
4. Release APK/AAB files must come from GitHub Actions only.
5. Never commit keystores, passwords, service-account files, `.env` values, exported user data or App Check debug tokens.
6. Keep the verified baseline branches read-only in normal work:
   - `stable/permanent-signed-2026-07-30`
   - `backup/pre-final-lock-2026-07-30`
   - `release/permanent-signed-v1`
7. Do not delete or force-push the baseline branches.

## GitHub settings to enforce manually

Repository administrators should configure these in GitHub Settings because they are account-level controls, not code changes:

- Prefer a private repository while the product is not intended to be open source.
- Protect `main` and the release branch against deletion and force pushes.
- Require pull requests and the `NearMeU quality gate` status check.
- Require conversation resolution before merge.
- Limit who can bypass branch protection.
- Enable secret scanning, push protection and Dependabot alerts.
- Keep Actions permissions at least privilege and restrict untrusted workflow changes.
- Store all Android signing values only in Actions secrets or an external encrypted vault.

## Backup map

### Source code

- Primary: GitHub `main`.
- Stable snapshot: `stable/permanent-signed-2026-07-30`.
- Pre-lock backup: `backup/pre-final-lock-2026-07-30`.
- Owner copy: local clone on a second disk.
- Monthly: encrypted `git bundle` stored outside the main PC.

### Android signing

Keep two encrypted copies of the permanent keystore in separate locations. Preserve alias, store password, key password, SHA-1 and SHA-256. Never paste or screenshot the keystore Base64 or passwords in chat, issues or logs.

### Firebase

- Firestore: daily export with at least 14 days retention, weekly retention for 8 weeks and monthly retention for 12 months.
- Storage: controlled private bucket replication compatible with user deletion and media-retention promises.
- Auth/configuration: preserve provider settings, authorized domains and App Check settings as private operational records.
- Run a staging restore test at least monthly and before production release.

## Recovery order

1. Freeze writes and preserve logs when data corruption or a security incident is suspected.
2. Roll back application code to the stable baseline branch.
3. Restore Firebase data into staging first.
4. Verify users, profiles, discovery, chats, blocks, reports, notifications and account deletion.
5. Restore production only after approval.
6. Re-enable traffic gradually and watch Crashlytics, Functions logs and billing.

## Product blueprint

```text
Flutter Android client
  ├─ Firebase Authentication
  ├─ Firebase App Check
  │   ├─ debug provider for trusted local debug builds
  │   └─ Play Integrity for Play-distributed release builds
  ├─ Firestore
  │   ├─ public discovery data
  │   ├─ owner-private account data
  │   ├─ chats and message metadata
  │   └─ moderation and system state
  ├─ Cloud Functions
  │   ├─ trusted reads/writes
  │   ├─ notifications
  │   ├─ retention and cleanup
  │   └─ account deletion and moderation
  ├─ Firebase Storage
  │   ├─ profile media
  │   └─ temporary private-chat media
  └─ encrypted app-private local chat/media store
```

## Roadmap

### Phase A — Current trusted-device baseline

Status: complete.

- Permanent signing configured.
- Firebase OAuth fingerprint configured.
- Debug App Check token registered on the trusted physical device.
- CI and physical smoke test passed.

### Phase B — Production security lock

- Make repository private unless open source is intentional.
- Enable GitHub branch protection and secret scanning.
- Verify least-privilege Firebase IAM and billing alerts.
- Deploy and verify current Firestore rules, indexes, Storage rules and Functions.
- Configure and test Play Integrity App Check for release builds before enforcement.

### Phase C — Release acceptance

- Test two real Android devices and separate accounts.
- Verify login, Nearby, filters, text/media/voice messages, push notifications, block/report, account deletion and reinstall.
- Produce signed AAB through the protected GitHub workflow.
- Release to Play Closed Testing first.

### Phase D — Production rollout

- Gradual rollout only after closed-testing exit criteria.
- Keep the previous Play version available for rollback.
- Monitor crashes, ANRs, backend errors, abuse reports and cost.
- Avoid adding calling, subscriptions or iOS work until the V1 reliability baseline is stable.

## Change-control rule

Any future change that touches authentication, App Check, Firebase rules, signing, account deletion, chat privacy or data retention requires: focused PR, automated tests, physical-device verification, rollback notes and an updated project-state record.
