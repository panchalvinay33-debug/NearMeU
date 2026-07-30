# NearMeU — Final Lock, Backup, Roadmap and Blueprint

## Official baseline

- Default branch: `main`
- Recovery branch: `stable/official-base-v1-2026-07-30`
- Base merge commit: `a743ffa407c145b3852c547d31f33458e8e839b4`
- Android package: `com.nearmeu.nearmeu`
- Permanent signing SHA-1: `7F:B6:4F:DB:90:B7:D1:27:57:5F:A4:F9:EE:69:2A:EC:BE:8E:7E:55`
- Permanent signing SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`

The permanent-signed Android baseline was physically verified for installation, Google Sign-In, App Check debug registration and Nearby discovery.

## GitHub lock

`main` is protected by an active ruleset that:

- requires a pull request
- requires `Flutter checks`
- requires `Firebase rules tests`
- requires `Cloud Functions checks`
- restricts deletion
- blocks force pushes

All future work starts from current `main` on a focused branch. Temporary branches are deleted after the merged result is proven stable.

## Backup map

### Source code

- Primary: GitHub `main`
- Recovery snapshot: `stable/official-base-v1-2026-07-30`
- Owner backup: local clone on a second encrypted drive
- Periodic backup: encrypted `git bundle` stored away from the main PC

### Android signing

Keep two encrypted copies of the permanent keystore in separate locations. Preserve alias, passwords and certificate fingerprints. Never commit or share the key, Base64 or passwords.

### Firebase and Play

Git does not contain live Firestore data, Firebase Console settings, App Check tokens, Play Console configuration or deployed backend revisions. Preserve these through controlled exports, console records and owner-managed backups.

Recommended production backup policy:

- Firestore daily exports with retention
- staging restore tests before major releases
- deployed rules/indexes/Functions revision records
- billing alerts and least-privilege IAM review

## Recovery order

1. Stop further changes and preserve logs.
2. Classify the failure: source, signing, Firebase, App Check, deployment or device state.
3. Create a recovery branch from `stable/official-base-v1-2026-07-30`.
4. Restore backend/data in staging first when needed.
5. Run required CI checks and physical smoke tests.
6. Return the fix to `main` through a pull request.
7. Record a new official recovery point only after it is proven better.

## Product blueprint

```text
Flutter Android client
  ├─ Firebase Authentication
  ├─ Firebase App Check
  │   ├─ debug provider for trusted debug builds
  │   └─ Play Integrity for Play-distributed releases
  ├─ Firestore
  │   ├─ public discovery data
  │   ├─ owner-private account data
  │   ├─ chats/message metadata
  │   └─ moderation/system state
  ├─ Cloud Functions
  │   ├─ trusted reads and writes
  │   ├─ notifications
  │   ├─ retention/cleanup
  │   └─ account deletion/moderation
  ├─ Firebase Storage
  │   ├─ profile media
  │   └─ temporary private-chat media
  └─ encrypted app-private local chat/media store
```

## Roadmap

### Complete

- Permanent Android signing
- Firebase OAuth fingerprints
- Debug App Check physical-device verification
- Nearby physical verification
- CI quality gate
- Clean branch structure
- Protected `main`
- Official recovery branch and playbook

### Still required before public launch

- Resolve and physically verify remaining issue #68 items
- Complete issue #41 production/Play setup
- Deploy and record Firebase rules, indexes, Storage rules and Functions
- Test Play Integrity through a Play testing track
- Complete two-account/two-device acceptance
- Build signed AAB through GitHub Actions
- Closed testing before production rollout
- Monitor crashes, ANRs, backend errors, abuse and cost

## Change-control rule

Any future change touching authentication, App Check, Firebase rules, signing, account deletion, chat privacy or retention requires a focused PR, automated tests, real-device verification, rollback notes and updated project-state documentation.