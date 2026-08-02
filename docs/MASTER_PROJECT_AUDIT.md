# NearMeU Master Project Audit

Last organized: 2026-08-02

This is the human-readable source of truth for NearMeU's accepted runtime, recovery position, current batch status and recovery procedure. Use it together with `config/project_state_manifest.json` and `docs/OFFICIAL_RECOVERABLE_BASE.md`.

## 1. Current official state

| Item | Official value |
|---|---|
| Repository | `panchalvinay33-debug/NearMeU` |
| Development source of truth | `main` |
| Recovery branch | `stable/official-recoverable-base` |
| Latest accepted batch | Batch 08 — profile sharing and deep-link recovery |
| Tested runtime commit | `fdc9b22322a96b793fff3058b1ca990f656e80a1` |
| Merged main runtime commit | `f83a6e92457f728f177dc062dcc9171c141a9217` |
| Accepted PR | `#100` |
| Android application ID | `com.nearmeu.nearmeu` |
| Firebase project | `nearmeu-e82c7` |
| Version | `1.0.11+12` |
| Physically tested signed debug APK SHA-256 | `4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412` |
| Signed release APK SHA-256 | `ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde` |
| Build | #90 / `30750777554` — PASS |
| Quality | #493 / `30750777555` — PASS |
| Owner acceptance | 2026-08-02 — ACCEPTED |
| Next batch | Batch 09 — Agora audio calling |

## 2. Accepted Batch 08 scope

Batch 08 adds privacy-safe profile sharing and Android deep-link recovery without changing accepted chat, Premium, deletion or recovery semantics.

Accepted behavior:

- sharing is explicit opt-in;
- public URLs use opaque revocable identifiers rather than Firebase UID/email/location;
- public web preview is generic and reveals no private profile details;
- signed-in active users resolve shared profiles through trusted backend logic;
- bidirectional blocks prevent shared-link bypass;
- suspended, missing, closed or permanently deleted profiles do not resolve;
- sharing can be disabled/re-enabled;
- reset rotates the identifier and invalidates the old URL;
- warm-start and cold-start HTTPS app links open the correct profile after the same-batch navigation-race fix;
- Auth deletion cleans up profile-sharing mappings;
- existing Batch 07 recovery behavior remains unchanged.

Known evidence notes: Batch 07 receiver-media pre/post-download recovery remains OWNER-DEFERRED / NOT PASS. Batch 08 custom-scheme fallback is implemented but was not separately captured as an independent physical screenshot; HTTPS warm/cold handling was physically verified.

## 3. Acceptance evidence

```text
Tested runtime: fdc9b22322a96b793fff3058b1ca990f656e80a1
Merged main runtime: f83a6e92457f728f177dc062dcc9171c141a9217
PR: #100
Version: 1.0.11+12
Build #90 / run 30750777554: PASS
Quality #493 / run 30750777555: PASS
Recoverable artifact ID: 8834500159
Recoverable artifact digest: sha256:f2515b2ce44e7d8ab4edbddb8060975dcc1c13e236a7a51f852f7a106b298c49
Tested debug APK SHA-256: 4fefcdb35ef6574887d31edbf5a21e95951f057bbb4e565102dd4dcff890f412
Signed release artifact ID: 8834548293
Signed release artifact digest: sha256:fc7348a6088c587670fda6d6bbde0e5c8ad9cb63fd7aa9156087132b3dfc762a
Signed release APK SHA-256: ec302b040a83fea86bafb77056172d7492a66a924343fed8138c305544b7ffde
Owner acceptance: 2026-08-02
```

Physical/backend matrix accepted: initial Profile Sharing load, opaque URL generation, Android share flow, generic web preview, warm/cold HTTPS deep links, disable/re-enable, rotation/old-link invalidation, block-bypass prevention and regression smoke all passed by owner report and/or backend evidence as recorded in `docs/BATCH_08_PHYSICAL_TEST.md`.

## 4. Production deployment

Batch 08 profile-sharing Functions and Firebase Hosting were deployed to `nearmeu-e82c7` and operationally verified on-device. The public Hosting preview also worked. Batch 08 did not change Firestore or Storage rules.

## 5. Canonical PC and recovery paths

| Purpose | Path |
|---|---|
| Canonical repository | `F:\NearMeU` |
| Local recovery folder | `F:\NearMeU\local_recovery` |
| Local tested APK target | `F:\NearMeU\local_recovery\NearMeU-Final-Tested-Base.apk` |
| Android platform tools | `C:\Users\dell\Downloads\platform-tools` |

The local recovery folder is owner-controlled and must not be committed.

## 6. Recovery procedure

```powershell
cd "F:\NearMeU"
git fetch origin
git checkout stable/official-recoverable-base
git reset --hard origin/stable/official-recoverable-base
git rev-parse HEAD
```

Immutable tested Batch 08 runtime:

```powershell
git checkout fdc9b22322a96b793fff3058b1ca990f656e80a1
```

Merged Batch 08 runtime:

```powershell
git checkout f83a6e92457f728f177dc062dcc9171c141a9217
```

## 7. Phone recovery rule

Install only a permanent-certificate-matching APK using update mode:

```powershell
cd "C:\Users\dell\Downloads\platform-tools"
.\adb.exe install -r "F:\NearMeU\local_recovery\NearMeU-Final-Tested-Base.apk"
```

Do not uninstall or clear app data for normal upgrades. Debug App Check tokens are installation-specific and must never be committed or documented.

## 8. Backup requirements

A complete recoverable base includes repository + exact accepted SHA, recovery branch, accepted APK/hash, signing-certificate evidence, permanent keystore in at least two encrypted owner-controlled locations, passwords separately, Firebase ownership/recovery access, Functions/Rules/Hosting source, deployment evidence, and owner acceptance evidence.

Never commit secrets, keys, passwords, App Check debug tokens, test credentials or live user data.

## 9. Execution roadmap

Accepted: Batches 00–08.

Next:

- Batch 09 — Agora audio calling
- Batch 10 — Agora video calling
- Batch 11 — owner-only Premium administration / purchase verification
- Batch 12 — full regression and Play Store readiness

No later runtime batch starts until Batch 08 final docs are merged, recovery branch is promoted and `F:\NearMeU` is synchronized.

## 10. Change control

`Select → Code → CI → Signed APK → Physical Test → Fix if needed → Owner Accept → Merge → Documents Update → Backup/Recovery Promote → Next Batch.`

`main` is development truth. `stable/official-recoverable-base` is last indisputably recoverable truth.

## 11. Document precedence

1. `docs/MASTER_PROJECT_AUDIT.md`
2. `config/project_state_manifest.json`
3. `docs/OFFICIAL_RECOVERABLE_BASE.md`
4. `docs/PRODUCT_DECISIONS.md`
5. `docs/EXECUTION_BATCH_PLAN.md`
6. `docs/TEST_BATCH_REGISTER.md`
7. Current `main` source, rules and workflows
8. Topic-specific runbooks and historical records
