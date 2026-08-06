# NearMeU Master Project Audit

Last organized: 2026-08-06

This audit records the accepted NearMeU history, current recovery position, why important corrective changes were made, and which evidence is authoritative. Operational rules live in `docs/PROJECT_OPERATING_BLUEPRINT.md`; exact machine recovery values live in `config/official_base_manifest.json`.

## 1. Project identity

| Item | Official value |
|---|---|
| Repository | `panchalvinay33-debug/NearMeU` |
| Canonical PC workspace | `F:\NearMeU` |
| Development source | `main` |
| Recovery branch | `stable/official-recoverable-base` |
| Android package | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| Version | `1.0.11+12` |
| Permanent signing cert SHA-256 | `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B` |
| Accepted product boundary | Batches 00–08 only |
| Future runtime work | LOCKED until explicit owner unlock |

Exact current official source SHA is intentionally stored only in `config/official_base_manifest.json` so recovery scripts and documentation use one value.

## 2. Accepted batch history

| Batch | Scope | Status |
|---|---|---|
| 00 | Governance, roadmap and controlled process | ACCEPTED |
| 01 | Chat reliability and message-state truth | ACCEPTED |
| 02 | Photo/video/voice-message reliability | ACCEPTED |
| 03 | Local-first persistence + seven-day temporary delivery cloud | ACCEPTED |
| 04 | Clear Chat / delete / unsend semantics | ACCEPTED |
| 05 | Identity continuity, close/reactivation | ACCEPTED |
| 06 | Premium entitlement foundation | ACCEPTED |
| 07 | Six-month Premium backup/restore architecture | ACCEPTED with deferred receiver-media evidence |
| 08 | Profile sharing + deep-link recovery | ACCEPTED; re-certification closeout underway |

No Batch09/Admin/calling experiment is part of the accepted runtime.

## 3. Original Base08 acceptance — 2026-08-02

Original Base08 added privacy-safe profile sharing and Android deep-link recovery without intentionally changing accepted chat, Premium, deletion or recovery semantics.

Authoritative original evidence:

- Tested runtime: `fdc9b22322a96b793fff3058b1ca990f656e80a1`
- Merged runtime: `f83a6e92457f728f177dc062dcc9171c141a9217`
- Accepted PR: `#100`
- Original closeout commit: `7f8b0c1f147a8de420ac54fa25c215fc22a7b299`
- Build #90 / run `30750777554`: PASS
- Quality #493 / run `30750777555`: PASS
- Recoverable artifact ID: `8834500159`
- Recoverable artifact digest: `sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49`
- Physically tested debug APK SHA-256: `4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412`
- Signed release artifact ID: `8834548293`
- Signed release artifact digest: `sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a`
- Signed release APK SHA-256: `ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde`
- Owner acceptance: 2026-08-02

Original accepted behavior included explicit opt-in sharing, opaque revocable identifiers, generic privacy-safe web preview, authenticated resolution, bidirectional block checks, sharing disable/re-enable, reset/rotation, HTTPS warm/cold app links and Auth-delete cleanup.

Evidence notes retained from original acceptance:

- Batch07 receiver-media pre-download/post-download Premium recovery remains OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS.
- Batch08 custom `nearmeu://` fallback is implemented but was not separately screenshot-verified. HTTPS warm/cold handling was physically verified.

## 4. Why Base08 was re-certified on 2026-08-06

Post-Base08 experimental work (Admin/calling) made the repository and production history harder to reason about. The owner explicitly chose to stop future work and return NearMeU to a clean, stable Base08 boundary before continuing anything else.

A cleanup branch restored the Base08 source tree and fresh physical regression testing was performed instead of relying only on old acceptance evidence.

PR `#112` — `Cleanup: restore exact accepted Base 08` — merged on 2026-08-06 with merge SHA `b6837ce2dd90bdc4db87a153089fcaf1cf74a441` after Base08 restoration plus narrowly scoped stabilization fixes.

## 5. Stabilization defects found during fresh re-certification

### 5.1 Firestore chat-index defect

Symptom: Chats/messages could fail with a Firestore failed-precondition requiring the normal collection descending index on `messages.timestamp`.

Cause: a later custom field override had replaced Firestore's automatic single-field collection index behavior.

Production correction restored the automatic field behavior using a clear-exemption operation. Repository cleanup prevents the stale custom timestamp override from being reintroduced.

Result: Chats physically loaded again.

### 5.2 Delivered grey-double-tick defect

Client delivery acknowledgement could submit up to 200 message IDs while the backend accepted only 100, allowing a backlog to reject the whole acknowledgement call.

Fix: backend delivery acknowledgement limit aligned to 200.

Result: fresh two-phone test physically verified single tick → grey delivered double tick → blue read double tick.

### 5.3 Online-presence defect

The chat screen periodically wrote last-seen state with `isOnline:false`. PresenceService cached its last published `true`, so it could fail to repair the externally changed stored state.

Fix: PresenceService compares stored profile state with desired lifecycle state and forces a corrective publish when they differ.

Result: fresh two-phone test physically verified mutual Online status.

### 5.4 About-screen version defect

The About screen hardcoded `Version 1.0.0` while the real package version is `1.0.11+12`.

PR `#114` changes About to use runtime `PackageInfo` and display `Version <version> (Build <buildNumber>)`. Automated candidate evidence is recorded in `config/official_base_manifest.json`. Focused physical About-screen verification is the remaining runtime closeout check at the time of this audit revision.

## 6. Fresh Base08 physical re-certification results

Owner-reported fresh PASS evidence includes:

- install/session continuity;
- Nearby;
- Chats;
- two-way text messaging;
- photo/video/voice messaging;
- message actions including unsend/delete-for-me/clear plus restart behavior;
- block/safety flows;
- Premium gating and owner Premium flow;
- Profile Sharing regression;
- restart/network smoke;
- two-device App Check setup;
- mutual Online presence;
- grey delivered double tick;
- blue read double tick;
- bidirectional two-device messaging.

The final About runtime-version display check remains tracked in the official base manifest until owner confirmation.

## 7. Fresh automated re-certification evidence

For the Base08 stabilization state before the About-only correction:

- Quality run `31077990662` / #612: PASS
- Recoverable build run `31077990677` / #166: PASS
- Recoverable artifact ID `8958542675`
- Recoverable artifact digest `sha256:a44c7a8d9f4f4098e0bde90c48d165b8a3198a173c67f63bb81a6b92e425aa9f`

For the About version-display candidate:

- PR `#114`
- Branch head `f0906b3be18e633102db07a6d74e837717d8cc60`
- Tested PR merge ref `04c0050ac13a9930996a59c351fea98c3971bbfb`
- Quality run `31081417470` / #614: PASS
- Recoverable run `31081418948` / #167: PASS
- Recoverable artifact ID `8959924645`
- Artifact digest `sha256:e9fa15ed8056fd44210b6f89917627236cfaa44d430209766351e63aab9bb27d`
- Signed debug APK SHA-256 `532e1b521f0fc92b63da8e4e68188e2788f2fda5996a8f753191b1594246c069`
- Permanent signing certificate verified

Do not mark PR114 as final accepted runtime until focused physical version display acceptance and merge/closeout gates complete.

## 8. Post-Base08 experiment cleanup

Historical Admin A01–A08 branches, Batch09 variants, Batch09 checkpoints, owner-control planning and safety branches were not accepted as the product base. On 2026-08-06 their branch tips were neutralized to the Base08-clean main state where deletion tooling was unavailable.

Closed PRs remain historical GitHub records only; they are not accepted source.

The final desired long-lived branch model is only:

- `main`
- `stable/official-recoverable-base`

## 9. Production Firebase boundary

Source rollback does not automatically delete already deployed Cloud Functions. Therefore an exact Base08 closeout requires a production-state audit.

Accepted Functions are defined by `functions/bootstrap.js`, which globally enforces App Check for client-invoked v2 HTTPS/callable functions and exports the accepted Base08 function modules.

Run:

```powershell
cd F:\NearMeU
.\tool\audit_production_state.ps1
```

Unexpected deployed Admin/calling/post-Base08 Functions are production drift and must be resolved before final recovery promotion.

No user data is deleted as part of source cleanup or normal recovery.

## 10. One-command recovery

Normal source recovery is:

```powershell
cd F:\NearMeU
.\tool\restore_official_base.ps1
```

The script reads the official SHA from `config/official_base_manifest.json`; operators do not need to remember old branch/commit identifiers.

The script refuses to destroy uncommitted work unless `-Force` is intentionally supplied.

## 11. Deployment process

Before production deployment:

```powershell
cd F:\NearMeU
.\tool\verify_deployment_gate.ps1
```

Deployment is allowed only from clean `main` exactly matching `origin/main`. Feature-branch production deploys are prohibited.

After deployment run the production-state audit and block acceptance if unexplained drift exists.

Full governing sequence:

`Freeze → Code → CI → Signed APK → Physical Test → Owner PASS → Merge → Exact-main Deploy → Production Audit → Docs → Recovery Promote → Local Sync → Branch Cleanup → Next Batch Unlock`

## 12. Backup and ownership requirements

A recoverable accepted base includes source SHA, recovery branch, official manifest, signed APK/hash, signing-certificate evidence, workflow/artifact IDs, production audit evidence and owner acceptance.

The permanent keystore must exist in at least two encrypted owner-controlled locations with passwords stored separately. Firebase/Google ownership recovery access must also be preserved.

Secrets, keystores, App Check debug tokens, credentials and live user data must never be committed.

## 13. Future roadmap state

Future runtime work is LOCKED. There is no active Batch09.

If the owner later chooses to continue, scope will be selected again and started fresh from the then-current official base. Old experimental branches must not be revived as the starting point.

## 14. Document precedence

1. `docs/PROJECT_OPERATING_BLUEPRINT.md`
2. `config/official_base_manifest.json`
3. `docs/MASTER_PROJECT_AUDIT.md`
4. `docs/OFFICIAL_RECOVERABLE_BASE.md`
5. `config/project_state_manifest.json`
6. `docs/TEST_BATCH_REGISTER.md`
7. `docs/EXECUTION_BATCH_PLAN.md`
8. accepted `main` source/rules/workflows
9. historical documents, old PRs/branches/issues
