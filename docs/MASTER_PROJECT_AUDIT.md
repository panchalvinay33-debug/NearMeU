# NearMeU Master Project Audit

Last organized: 2026-08-02

This is the human-readable source of truth for NearMeU's accepted runtime, recovery position, current batch status and recovery procedure. When this document conflicts with older notes, use this document together with `config/project_state_manifest.json` and `docs/OFFICIAL_RECOVERABLE_BASE.md`.

## 1. Current official state

| Item | Official value |
|---|---|
| Repository | `panchalvinay33-debug/NearMeU` |
| Development source of truth | `main` |
| Recovery branch | `stable/official-recoverable-base` |
| Latest accepted batch | Batch 07 — six-month Premium backup and restore |
| Tested runtime commit | `5ae058122d927c7e35257fb80ca5fa879f14b784` |
| Merged main runtime commit | `db48338e6528b61e1e486d6d158c9d62e641c977` |
| Accepted PR | `#98` |
| Android application ID | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| Version | `1.0.10+11` |
| Physically tested signed debug APK SHA-256 | `2af784329a1594a761877110c671508b19f8cd1cc2542d9079cc46a7b80025d1` |
| Signed release APK SHA-256 | `19a100dcfa64dc00bb71e918452d8c70d902d2b42ced8e72e6ef04eef5568442` |
| Build | #79 / `30746260270` — PASS |
| Quality | #480 / `30746260318` — PASS |
| Owner acceptance | 2026-08-02 — ACCEPTED |
| Next batch | Batch 08 — profile sharing and deep-link recovery |

## 2. Accepted Batch 07 scope

Batch 07 adds a separate per-user Premium recovery layer independent from the seven-day delivery cloud. New eligible recovery assignments use trusted server-side Premium entitlement truth and recorded six-calendar-month expiry. Restore writes into the encrypted local chat store and is idempotent.

Accepted semantics:

- Premium text recovery restores after an approved local DB reset.
- Premium sent photo recovery restores and renders.
- Clear Chat purges/blocks recovery for the clearing user and does not affect the other participant's copy.
- Delete for Me removes only that user's recovery copy.
- Delete for Everyone / Unsend removes both participants' recovery copies and original content does not resurrect.
- Seven-day temporary delivery-cloud behavior remains separate and continued to deliver/render fresh media in regression testing.
- Free users are rejected by the trusted Premium recovery callable.
- Reversible Close Account retains the Auth identity; permanent Auth deletion has recovery cleanup/retry handling.
- Actual audio/video call media is never backed up.

Known evidence gap: receiver-side media pre-download versus post-download recovery eligibility is implemented but its dedicated two-device physical proof was **OWNER-DEFERRED**. It is **not** recorded as PASS.

## 3. Acceptance evidence

Final accepted runtime evidence:

```text
Tested runtime: 5ae058122d927c7e35257fb80ca5fa879f14b784
Merged main runtime: db48338e6528b61e1e486d6d158c9d62e641c977
PR: #98
Version: 1.0.10+11
Build #79 / run 30746260270: PASS
Quality #480 / run 30746260318: PASS
Recoverable artifact ID: 8833110504
Recoverable artifact digest: sha256:75892030fb34647b64b89fd6f1ac3a94b48acac6bf24217eb63b69a5feb5c6fc
Tested debug APK SHA-256: 2af784329a1594a761877110c671508b19f8cd1cc2542d9079cc46a7b80025d1
Signed release artifact ID: 8833182373
Signed release artifact digest: sha256:4bc19b26851ab9349a578fb9fe64b6d609af16e0ff9da2432194a25106e4b403
Signed release APK SHA-256: 19a100dcfa64dc00bb71e918452d8c70d902d2b42ced8e72e6ef04eef5568442
Owner acceptance: 2026-08-02
```

Physical/backend matrix accepted:

- direct-update continuity — PASS;
- same login/chats/media preserved — PASS;
- Premium text restore — PASS;
- Premium sent photo restore — PASS;
- Clear Chat preview + non-resurrection — PASS;
- Delete for Me preview + non-resurrection — PASS;
- Unsend/Delete for Everyone preview + non-resurrection — PASS;
- cross-account Clear Chat isolation — PASS;
- seven-day delivery-cloud quick regression — PASS;
- Free Premium recovery authorization — backend-enforced PASS;
- receiver media pre/post-download recovery — OWNER-DEFERRED / NOT PASS.

## 4. Production deployment

Batch 07 recovery functions and Storage Rules were deployed to Firebase project `nearmeu-e82c7` on 2026-08-02. Owner terminal evidence ended with `Deploy complete!`. App Check debug-provider behavior remains test-only; Play Integrity production readiness is a Batch 12 concern.

## 5. Canonical PC and recovery paths

| Purpose | Path |
|---|---|
| Canonical repository | `F:\NearMeU` |
| Local recovery folder | `F:\NearMeU\local_recovery` |
| Local tested APK target | `F:\NearMeU\local_recovery\NearMeU-Final-Tested-Base.apk` |
| Android platform tools | `C:\Users\dell\Downloads\platform-tools` |

The local recovery folder is owner-controlled and must not be committed.

## 6. Source recovery

After promotion:

```powershell
cd "F:\NearMeU"
git fetch origin
git checkout main
git reset --hard origin/main
git status
```

Official recovery source:

```powershell
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
git rev-parse HEAD
```

Immutable tested runtime:

```powershell
git checkout 5ae058122d927c7e35257fb80ca5fa879f14b784
```

Merged Batch 07 runtime:

```powershell
git checkout db48338e6528b61e1e486d6d158c9d62e641c977
```

## 7. Phone recovery rule

Use only a permanent-certificate-matching APK and update mode:

```powershell
cd "C:\Users\dell\Downloads\platform-tools"
.\adb.exe install -r "F:\NearMeU\local_recovery\NearMeU-Final-Tested-Base.apk"
```

Do not uninstall or clear app data for normal upgrades. Debug App Check tokens are installation-specific and must never be committed or copied into documentation.

## 8. Backup requirements

A complete recoverable base includes repository + exact accepted SHA, recovery branch, accepted APK/hash, signing certificate evidence, permanent keystore in at least two encrypted owner-controlled locations, passwords stored separately, Firebase ownership/recovery access, Functions/Rules source, deployment evidence, Play ownership records when enabled, and owner acceptance evidence.

Never commit secrets, keys, passwords, App Check debug tokens, test credentials or live user data.

## 9. Execution roadmap

Accepted: Batches 00–07.

Next:

- Batch 08 — profile sharing and deep-link recovery
- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — owner-only Premium administration / purchase verification
- Batch 12 — full regression and Play Store readiness

No later runtime batch starts until the current accepted state is documented, the recovery branch is promoted and `F:\NearMeU` is synchronized.

## 10. Change control

`Select → Code → CI → Signed APK → Physical Test → Fix if needed → Owner Accept → Merge → Documents Update → Backup/Recovery Promote → Next Batch.`

`main` is development truth. `stable/official-recoverable-base` is last indisputably recoverable truth. The recovery branch moves only after accepted runtime evidence and final documentation are complete.

## 11. Document precedence

1. `docs/MASTER_PROJECT_AUDIT.md`
2. `config/project_state_manifest.json`
3. `docs/OFFICIAL_RECOVERABLE_BASE.md`
4. `docs/PRODUCT_DECISIONS.md`
5. `docs/EXECUTION_BATCH_PLAN.md`
6. `docs/TEST_BATCH_REGISTER.md`
7. Current `main` source, rules and workflows
8. Topic-specific runbooks and historical records
