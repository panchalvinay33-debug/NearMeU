# NearMeU Controlled Execution Batch Plan

Last updated: 2026-07-31

This is the operational plan for taking NearMeU from the accepted recoverable base to Play Store release. Every runtime change must be completed as one focused batch. A later batch must not begin until the current batch has passed its required automated tests, signed APK build, physical-device checks, owner review and documentation update.

## Governing rule

One batch means:

1. Start from current `main`.
2. Create one short-lived branch.
3. Freeze the scope before coding.
4. Implement only that batch.
5. Run automated tests and required Firebase tests.
6. Build a signed test APK for runtime changes.
7. Install with `adb install -r` unless a clean-install scenario is specifically required.
8. Test on physical Android device(s).
9. Fix failures on the same branch and rebuild.
10. Record the final commit, APK name, SHA-256, devices, accounts, scenarios, results and known limitations.
11. Obtain owner acceptance.
12. Merge through a pull request.
13. Rebuild and verify the merged `main` state when required.
14. Move `stable/official-recoverable-base` only after merged-main acceptance and recovery evidence are complete.
15. Update the master audit, manifest, this plan and the batch register.
16. Delete the temporary branch.

No batch is accepted merely because code compiles. Runtime changes require a tested APK and owner approval.

## Accepted starting point

- Repository: `panchalvinay33-debug/NearMeU`
- Source branch: `main`
- Recovery branch: `stable/official-recoverable-base`
- Accepted runtime commit: `f9bc38572c715a017c8b261a5d805aa125ffe7a5`
- Current documentation head at plan creation: `c414810c8a483f44debb8ba67fce3156c8718d7f`
- Accepted APK SHA-256: `587CD1B328A1CAEB659A0C5D0604609C5E6A381B61EFC6D0ACD9D3C2B1BDE00C`

The documentation head does not replace the accepted runtime base until a later runtime batch completes the full acceptance process.

## Batch 00 — Governance, roadmap and decision freeze

Scope:

- Record the latest demo-video observations.
- Separate implemented, partially implemented, unverified, planned and deferred work.
- Freeze Premium, media, calling, clear-chat, identity, account-close, profile-sharing and admin-premium decisions.
- Establish the batch register and acceptance template.
- Define when `main` and the recovery branch may move.

Testing gate:

- Documentation paths resolve.
- Manifest JSON is valid.
- No runtime, Firebase rule or deployment change.
- Existing accepted runtime and APK remain unchanged.

## Batch 01 — Chat reliability and message-state truth

Scope:

- Formal states: pending, server accepted, delivered to receiver device, read, failed.
- UI: sending indicator, single tick, grey double tick, blue double tick, retry state.
- Delivery acknowledgement separate from read acknowledgement.
- Unread counters and chat-list preview convergence.
- Duplicate-send and restart recovery checks.

Required physical tests:

- Two accounts and preferably two phones.
- Both online.
- Receiver app open, backgrounded and terminated.
- Receiver offline then reconnects.
- Notification-open flow.
- Sender and receiver restarts.
- Rapid-message sequence.
- Weak-network interruption.

Acceptance:

- Single tick means server accepted.
- Grey double tick means receiver device synchronized the message.
- Blue double tick means receiver opened/read it.
- Unread counts agree across chat list, chat screen and restart.

## Batch 02 — Photo, video and voice-message reliability

Scope:

- One shared media lifecycle: prepare, compress, upload, create message, download, save locally, acknowledge, retry and clean up.
- Clear progress states and cancellation.
- Orphan-file prevention.
- Duplicate-tap prevention.
- Receiver-local persistence.

Tests include small/large photo, short/limit video, voice note, slow network, interrupted upload, app background/kill, denied permission, low storage and receiver offline.

## Batch 03 — Local-first persistence and seven-day delivery cloud

Product rule:

- Successfully downloaded text/media remains in app-private local storage until Clear Chat, applicable message deletion, app-data clear or uninstall.
- Seven days applies to the temporary cloud delivery copy, not to the local copy.
- Cloud cleanup must never remove an available local copy.
- No expired placeholder is shown while a valid local file exists.

Tests include simulated cloud expiry, offline replay after expiry, app restart and a new device without Premium backup.

## Batch 04 — Clear Chat and deletion semantics

Scope:

- `Clear Chat` in every individual chat `⋮` menu.
- Clearer-side permanent deletion from local database, local files, user-specific recovery, all of that user's devices and chat list.
- Other participant remains unaffected.
- Clear Chat, Delete for Me and Delete for Everyone remain separate actions.
- Cleared content must not return after reinstall or Premium restore.

## Batch 05 — Identity, account close and reactivation

Rules:

- One verified email maps to one continuing NearMeU identity.
- Close Account removes public profile details and availability but preserves the internal identity, relationships and block records.
- Same verified email reactivates the same identity.
- Cleared chats and permanently deleted content never return.
- Permanent account deletion is a separate irreversible flow.

## Batch 06 — Premium entitlement foundation

One private plan unlocks:

- Photo sending.
- Video sending.
- Voice-message sending.
- Voice-call initiation.
- Video-call initiation.
- Up to six months of eligible automatic chat/media recovery.

No public Premium badge, coins, multiple packs or public subscription status.

Entitlement sources:

- Google Play purchase.
- Owner-admin timed grant.

Security gates are required in UI, backend and upload authorization.

## Batch 07 — Six-month automatic Premium backup and restore

Scope:

- Per-user recovery of eligible text, sent/received downloaded media, reply context and call-history metadata.
- Automatic encrypted backup while covered by Premium retention.
- Same-account reinstall/phone-change restore.
- Clear Chat permanent purge.
- Account-close retention and reactivation behavior.
- Premium expiry does not immediately erase already assigned retention.

Actual calls are never recorded.

## Batch 08 — Profile sharing and deferred deep-link recovery

Scope:

- Public revocable profile identifier, never internal UID/email/phone/exact location.
- Installed app opens the profile directly.
- Web fallback offers limited preview and Play Store installation.
- Install/referrer flow attempts to resume the shared profile.
- Sharing-off, reset-link, block, suspension and closed-account rules.

Available to Free and Premium users.

## Batch 09 — Agora audio calling

Scope:

- Secure token service.
- Premium caller, Free/Premium receiver.
- Incoming notification, accept, reject, busy, missed, reconnect and end.
- Background, locked-screen, speaker, Bluetooth and mute behavior.
- Block, suspension, rate-limit and spam checks.
- Call-history metadata only; no recording.

Audio must be accepted before video work begins.

## Batch 10 — Agora video calling

Scope:

- Camera permission and lifecycle.
- Local preview and remote video.
- Front/back switch and camera-off state.
- Weak-network adaptation, background/foreground, lock-screen, thermal and battery testing.
- No group calls and no recording.

## Batch 11 — Owner-only Premium administration

The current app has one owner administrator only. Multi-admin roles are deliberately deferred.

Scope:

- Active Premium count.
- Purchased/admin-granted source filters.
- Expiring-soon view.
- Timed grant, custom expiry, extension and admin-grant revocation.
- Paid Google Play entitlement is not silently cancelled by admin-grant removal.
- Audit record for owner actions.

## Batch 12 — Full regression and Play Store readiness

Scope:

- Complete functional regression.
- Rules, Functions and Flutter tests.
- Release AAB and Play App Signing path.
- Play Integrity App Check.
- Privacy Policy, Terms, Community Guidelines, Data Safety and account-deletion disclosures.
- Internal testing, closed testing and staged rollout.
- Crash/ANR and privacy-safe observability review.

## Batch acceptance record template

Every batch record must include:

```text
Batch ID:
Branch:
Base commit:
Final branch commit:
Pull request:
Merged main commit:
Recovery branch commit:
APK/AAB filename:
APK/AAB SHA-256:
Signing certificate identity:
Test device(s):
Android version(s):
Test account(s):
Automated tests:
Firebase rules tests:
Cloud Functions tests:
Physical scenarios tested:
Passed:
Failed:
Known limitations:
Owner decision:
Documentation updated:
Next batch:
```

## Recovery-base movement rule

`main` is the current accepted development truth after merge. `stable/official-recoverable-base` is the last indisputably recoverable runtime truth.

The recovery branch moves only when:

- The merged `main` commit is built again or its accepted artifact is cryptographically tied to that exact commit.
- The signed APK/AAB hash and signing identity are recorded.
- Required physical tests pass on the merged state.
- Recovery instructions are verified.
- The owner explicitly accepts the new base.

Documentation-only batches do not replace the accepted runtime commit or APK.