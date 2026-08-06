# NearMeU Controlled Execution Batch Plan

Last updated: 2026-08-06

NearMeU is currently frozen at **Base 08**. No post-Base08 runtime batch is active.

## Governing rule

Every runtime batch follows exactly:

`Freeze scope → branch from official base → code → CI → permanently signed APK → focused physical test → owner PASS → merge → production deploy from exact main SHA when required → production-state audit → docs → recovery promotion → local sync → temporary branch cleanup → next batch unlock`

A batch is not accepted merely because a PR merged or CI passed.

## Hard gates

1. Start only from the current official base in `config/official_base_manifest.json`.
2. Use canonical workspace `F:\NearMeU`.
3. Only one active runtime batch at a time.
4. Freeze scope before coding.
5. Use one short-lived runtime/stabilization branch.
6. Run applicable Flutter, Firebase Rules and Cloud Functions checks.
7. Build with the permanent NearMeU Android signing certificate.
8. Install normal test upgrades using `adb install -r`; do not uninstall/wipe unless the test explicitly requires destructive behavior.
9. Preserve package `com.nearmeu.nearmeu` and follow increasing versionCode rules for distributed builds.
10. Physically test the exact signed candidate plus required regression smoke.
11. Owner accepts or rejects the exact candidate.
12. Merge only through a passing PR.
13. If production resources changed, deploy only from clean `main` exactly matching `origin/main`.
14. Run `tool/verify_deployment_gate.ps1` before production deployment.
15. Run `tool/audit_production_state.ps1` after production deployment.
16. Unexpected deployed Functions or unexplained production drift block acceptance.
17. Update `config/official_base_manifest.json` and authoritative docs.
18. Promote `stable/official-recoverable-base` only after all acceptance/production gates pass.
19. Synchronize `F:\NearMeU` to the promoted accepted state.
20. Delete temporary branches when possible; otherwise neutralize them to the accepted base and leave no unique active runtime code.
21. Only then can the owner explicitly unlock the next batch.

## Current accepted product boundary

Batches 00 through 08 are the accepted product boundary.

### Batch 00 — Governance / roadmap foundation
Status: ACCEPTED.

### Batch 01 — Chat reliability and message-state truth
Status: ACCEPTED.

### Batch 02 — Photo/video/voice-message reliability
Status: ACCEPTED.

### Batch 03 — Local-first persistence and seven-day temporary delivery cloud
Status: ACCEPTED.

### Batch 04 — Clear Chat and deletion semantics
Status: ACCEPTED.

### Batch 05 — Identity, account close and reactivation
Status: ACCEPTED.

### Batch 06 — Premium entitlement foundation
Status: ACCEPTED.

### Batch 07 — Six-month Premium backup and restore
Status: ACCEPTED with a persistent evidence gap: receiver-media pre-download/post-download Premium recovery remains OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS.

### Batch 08 — Profile sharing and deep-link recovery
Status: ACCEPTED original scope; Base08 re-certification closeout in progress as recorded in `config/official_base_manifest.json`.

Re-certification stabilization includes only Base08 reliability/operability work: Firestore chat-index correction, delivered-receipt batch alignment, online-presence correction and accurate runtime About-screen version display.

## Future roadmap

Future work is **LOCKED**, not active.

Historical names such as Batch09 audio calling, Batch10 video calling, Admin experiments or other post-Base08 branches/PRs are planning/history only. They are not accepted source and must not be treated as current scope.

When the owner later chooses to continue, the next scope will be freshly selected from the roadmap and started from the then-current official recoverable base. Old experimental branches are never used as a starting point.

## Recovery-base rule

The recovery branch is the last indisputably recoverable truth. It moves only after CI, permanent signing, physical acceptance, required production actions, production-state audit, documentation and owner acceptance are complete.

Recovery itself is performed with:

```powershell
cd F:\NearMeU
.\tool\restore_official_base.ps1
```

No manual search for old SHAs should be required during normal recovery.
