# NearMeU Master Project Audit

Last organized: 2026-07-31

This file is the human-readable starting point for every NearMeU audit. It explains the exact accepted runtime base, current documentation head, PC recovery paths, tested APK, backup blueprint, execution batches, change control and external dependencies intentionally kept outside GitHub.

## 1. Current official state

| Item | Official value |
|---|---|
| Repository | `panchalvinay33-debug/NearMeU` |
| Development source of truth | `main` |
| Recovery branch | `stable/official-recoverable-base` |
| Accepted runtime commit | `f9bc38572c715a017c8b261a5d805aa125ffe7a5` |
| Documentation head before Batch 00 | `c414810c8a483f44debb8ba67fce3156c8718d7f` |
| Branch relationship | `main` may contain documentation/governance commits beyond the accepted runtime; the recovery branch remains the last accepted runtime truth |
| Android application ID | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| Accepted test APK SHA-256 | `587CD1B328A1CAEB659A0C5D0604609C5E6A381B61EFC6D0ACD9D3C2B1BDE00C` |
| Active production checklist | Issue `#41 Complete NearMeU production launch setup` |
| Production deployment | Not performed as part of the accepted base |

The accepted runtime base is the application state installed on the owner's Android phone with `adb install -r` and approved after login, Nearby and chat recovery checks. Documentation-only commits do not replace that runtime acceptance or APK.

## 2. What is included in the accepted runtime base

- Flutter Android application source.
- Firebase Authentication integration.
- Nearby discovery and distance filtering.
- One-to-one private chat.
- Text, emoji, reply, photo, video and voice-message code paths.
- Encrypted local-first chat storage.
- Presence, unread, blocking, reporting and account controls.
- Firestore and Storage security rules and tests.
- Cloud Functions source and tests.
- Permanent Android signing restoration through protected GitHub Actions secrets.
- Google Sign-In-compatible signing identity.
- Firebase App Check debug testing flow.
- Canonical quality workflow and recoverable APK workflow.
- Recovery, roadmap, backup and production runbooks.

Items listed as included are not automatically considered fully regression-tested. The machine-readable manifest and test batch register distinguish implementation from complete acceptance.

## 3. Verified acceptance evidence

The accepted runtime state passed:

- Flutter dependency resolution.
- Flutter tests.
- GitHub Flutter quality checks.
- Firebase rules tests.
- Cloud Functions tests.
- Permanently signed debug APK build.
- APK certificate verification.
- Recovery manifest and checksum generation.
- Physical installation using update mode (`adb install -r`).
- Google Sign-In and authenticated app opening.
- Nearby recovery after registering the installed App Check debug token.
- Chat access on the accepted phone installation.

`flutter analyze` reports existing warnings and informational lints. These are technical debt, not compile failures. They must be cleaned in focused, test-backed batches without weakening the accepted base.

## 4. Latest demo evidence and observed gaps

The owner-supplied latest demo showed reachable flows for Google sign-in/onboarding, Nearby/search/filter, one-to-one chat, text, photo/video preparation, voice-message playback, profile, block, settings, blocked users, owner admin dashboard, user management and reports.

The demo is evidence of visible behavior, not a substitute for controlled two-device acceptance. Key gaps to address in later batches:

- Message UI appears to distinguish sent and seen, but not a separately acknowledged delivered-to-device state.
- Unread/read behavior requires controlled two-account/two-device testing, including offline and restart cases.
- Media preparation/upload needs clearer progress, cancellation and retry behavior.
- Nearby loading needs timeout, offline and retry polish.
- Premium, six-month automatic recovery, seven-day delivery-cloud cleanup, Clear Chat permanent purge, account-close reactivation, profile sharing and Agora calling are approved/planned work until individually implemented and accepted.

## 5. PC setup and local backup

Owner PC paths recorded during acceptance:

| Purpose | Path |
|---|---|
| Clean repository clone | `F:\NearMeU` |
| Local tested APK folder | `F:\NearMeU\local_recovery` |
| Local tested APK | `F:\NearMeU\local_recovery\NearMeU-Final-Tested-Base.apk` |
| Android platform tools | `C:\Users\dell\Downloads\platform-tools` |
| Downloaded accepted APK | `C:\Users\dell\Downloads\NearMeU-Official-Recoverable-Base.apk` |

The `local_recovery/` directory is excluded locally through `.git/info/exclude`; it is not committed to GitHub.

Accepted runtime verification:

```text
accepted runtime commit: f9bc38572c715a017c8b261a5d805aa125ffe7a5
recovery branch: stable/official-recoverable-base
accepted APK SHA-256: 587CD1B328A1CAEB659A0C5D0604609C5E6A381B61EFC6D0ACD9D3C2B1BDE00C
```

The current `main` head must be checked separately because documentation or later accepted batches may move it beyond the runtime commit.

## 6. Fast source recovery on the PC

For current development source:

```powershell
cd "F:\NearMeU"
git fetch origin
git checkout main
git reset --hard origin/main
git clean -fd
git rev-parse HEAD
git status
```

For the last accepted runtime/recovery source:

```powershell
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
git rev-parse HEAD
```

Expected accepted runtime SHA until a later base is formally accepted:

```text
f9bc38572c715a017c8b261a5d805aa125ffe7a5
```

Immutable checkout:

```powershell
git checkout f9bc38572c715a017c8b261a5d805aa125ffe7a5
```

## 7. Fast phone recovery

Do not uninstall or clear app data unless necessary, because App Check debug registration is installation-specific.

```powershell
cd "C:\Users\dell\Downloads\platform-tools"
.\adb.exe devices
.\adb.exe install -r "F:\NearMeU\local_recovery\NearMeU-Final-Tested-Base.apk"
```

Expected result:

```text
Performing Streamed Install
Success
```

After installation verify login, Nearby, chat history, message send/receive and app restart.

## 8. App Check dependency

The test APK uses Firebase App Check debug provider. The debug token is generated by the specific installed app data and is intentionally outside Git.

- Never commit an App Check debug token.
- Never place it in documentation, source or public logs.
- Uninstalling or clearing data may generate a new token.
- Register the current token in Firebase Console before expecting Nearby/chat-backed Firebase requests to work.
- Any token exposed outside the owner's secure environment must be deleted or rotated.

Production App Check through Play Integrity is a separate owner-approved release step.

## 9. Backup blueprint

A complete NearMeU recovery set is not only a Git commit. Owner-controlled recovery must include:

1. GitHub repository and accepted commit SHA.
2. `stable/official-recoverable-base` branch.
3. Accepted APK and SHA-256 checksum.
4. Recovery manifest and signing certificate report from GitHub Actions.
5. Permanent Android keystore in at least two encrypted owner-controlled locations.
6. Keystore alias and passwords in a password manager separate from the keystore file.
7. GitHub Actions signing secrets and repository ownership access.
8. Firebase project ownership and recovery access.
9. Firestore rules, Storage rules, indexes and Functions source.
10. Production deployment/version records when deployment begins.
11. Google Play Console ownership and Play App Signing records when enabled.
12. Legal-policy source files and published URLs before release.
13. Accepted batch evidence: commit, artifact hash, devices, scenarios and owner decision.

Secrets, private keys, passwords, test-account credentials and live user data must not be committed to GitHub.

## 10. Approved product direction

The canonical owner-approved behavior is recorded in [`PRODUCT_DECISIONS.md`](PRODUCT_DECISIONS.md). Summary:

- One private Premium plan.
- Premium unlocks photo, video and voice-message sending, voice/video-call initiation and up to six months of eligible automatic recovery.
- Free users retain text chat and can receive media and calls.
- No public Premium badge, coins or multiple packs.
- Successfully saved media remains app-local until Clear Chat, deletion, app-data clear or uninstall.
- Seven days applies only to temporary delivery-cloud media.
- Clear Chat permanently purges the clearer's local and recoverable copy across that user's devices without deleting the other participant's copy.
- One verified email maps to one continuing identity; Account Close is reversible reactivation, while permanent deletion is separate.
- Blocks survive reinstall, close and reactivation.
- Profile sharing is available to Free and Premium users through a revocable public identifier.
- Agora is selected for planned audio/video calling; audio is accepted before video.
- One owner-admin manages timed Premium grants; multi-admin roles are deferred.

These are approved decisions, not claims of completed implementation.

## 11. Controlled execution roadmap

The detailed sequence and acceptance gates are in [`EXECUTION_BATCH_PLAN.md`](EXECUTION_BATCH_PLAN.md). The live status is in [`TEST_BATCH_REGISTER.md`](TEST_BATCH_REGISTER.md).

Order:

1. Batch 00 — governance, roadmap and decision freeze.
2. Batch 01 — chat reliability and message-state truth.
3. Batch 02 — photo/video/voice-message reliability.
4. Batch 03 — local-first persistence and seven-day delivery cloud.
5. Batch 04 — Clear Chat and deletion semantics.
6. Batch 05 — identity, Account Close and reactivation.
7. Batch 06 — Premium entitlement foundation.
8. Batch 07 — six-month automatic Premium backup/restore.
9. Batch 08 — profile sharing and deep-link recovery.
10. Batch 09 — Agora audio calling.
11. Batch 10 — Agora video calling.
12. Batch 11 — owner-only Premium administration.
13. Batch 12 — full regression and Play Store readiness.

A later runtime batch does not begin before the active runtime batch completes required tests and owner acceptance.

## 12. Change-control rule

1. Start from current `main`.
2. Create one focused short-lived branch.
3. Freeze the batch scope.
4. Make only the necessary changes.
5. Run required automated and Firebase tests.
6. Build an installable signed test APK for runtime/config changes.
7. Test on physical Android device(s), using two accounts/devices where required.
8. Fix all batch-blocking failures on the same branch and rebuild.
9. Record final commit, artifact hash, devices, scenarios, failures and limitations.
10. Obtain owner approval.
11. Merge through a pull request.
12. Verify merged `main` where required.
13. Move `stable/official-recoverable-base` only after merged-main runtime acceptance and recovery evidence.
14. Update this audit, manifest, execution plan, batch register and recovery record.
15. Delete the temporary branch.

No production Firebase deploy, signing rotation, Play upload or public rollout may occur without explicit owner approval.

## 13. Recovery-branch movement

`main` is the development source of truth. `stable/official-recoverable-base` is the last indisputably recoverable runtime truth.

The recovery branch moves only when:

- The accepted artifact is tied to the exact merged-main commit.
- Signing identity and SHA-256 are recorded.
- Required physical tests pass on the merged state.
- Recovery instructions are verified.
- The owner explicitly accepts the new base.

Documentation-only batches do not move the recovery branch and do not replace the accepted runtime APK.

## 14. Document precedence

When records disagree, use this order:

1. `docs/MASTER_PROJECT_AUDIT.md`
2. `config/project_state_manifest.json`
3. `docs/OFFICIAL_RECOVERABLE_BASE.md`
4. `docs/PRODUCT_DECISIONS.md`
5. `docs/EXECUTION_BATCH_PLAN.md`
6. `docs/TEST_BATCH_REGISTER.md`
7. Current `main` source, rules and workflows
8. `docs/INDEX.md` and topic-specific runbooks
9. Historical plans and closed issues/PRs

## 15. Audit result at Batch 00 start

Long-lived branches remain:

- `main`
- `stable/official-recoverable-base`

Batch work occurs only on a temporary branch. Historical PRs and commits are history, not alternate supported recovery bases. The accepted runtime remains `f9bc385...` and its accepted APK hash until a later runtime batch satisfies the full acceptance and recovery-base movement rules.