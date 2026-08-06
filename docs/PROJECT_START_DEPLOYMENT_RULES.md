# NearMeU Project Start and Deployment Rules

Status: permanent governance rule
Applies to: NearMeU consumer app, shared Firebase backend, and the NearMeU-Admin companion project

## 1. Project identity must be established first

Whenever NearMeU work starts, the operator must first confirm:

- consumer repository: `panchalvinay33-debug/NearMeU`
- canonical PC workspace: `F:\NearMeU`
- consumer Android package: `com.nearmeu.nearmeu`
- companion Admin repository: `panchalvinay33-debug/NearMeU-Admin`
- Admin Android package: `com.nearmeu.admin`
- shared Firebase project: `nearmeu-e82c7`
- shared backend owner repository: `panchalvinay33-debug/NearMeU`
- production deployment branch: `main`
- official recovery branch: `stable/official-recoverable-base`
- planned RTC provider for Batch09/10: Agora

NearMeU and NearMeU-Admin are one product ecosystem but remain separate applications, repositories, releases and recovery boundaries.

## 2. Mandatory project-opening sequence

Before any runtime development or production deployment, establish the official source of truth:

```powershell
cd F:\NearMeU
git fetch --prune origin
git switch main
git reset --hard origin/main
.\tool\show_project_state.ps1
```

If the working tree contains intentional uncommitted work, save or branch it first instead of resetting it.

If project state is unclear or damaged, use the official recovery process rather than reconstructing the project from historical branches.

## 3. Accepted-base protection

The current promoted accepted base is the only valid starting point for new runtime work.

Every new runtime batch follows:

`accepted base -> fresh narrow branch -> code -> CI -> permanently signed candidate -> focused physical test -> owner PASS -> merge -> exact-main production deployment when required -> production audit -> documentation -> immutable acceptance/recovery promotion -> cleanup`

Historical branches, closed experiments, Admin A01-A08 branches, old Batch09 branches, screenshots or local copies must never override the current accepted base.

## 4. Production deployment ownership

Production Firebase resources for the shared `nearmeu-e82c7` project are deployed only from a clean checkout of `panchalvinay33-debug/NearMeU` on exact `main`.

Never deploy the shared Firebase production backend from:

- `NearMeU-Admin`;
- a historical Admin branch;
- a Batch09/calling experiment branch;
- an unmerged feature branch;
- a dirty working tree;
- a local commit that does not equal `origin/main`.

Before a production deployment:

```powershell
.\tool\verify_deployment_gate.ps1
```

After a production deployment or production cleanup:

```powershell
.\tool\audit_production_state.ps1
```

A deployment is not accepted while unexplained production drift exists.

## 5. Consumer/Admin code ownership

Consumer UI/runtime belongs in `NearMeU`.

Admin UI/runtime belongs in `NearMeU-Admin`.

Shared privileged backend contracts remain owned by `NearMeU` unless governance explicitly changes that ownership later.

When a future Admin feature needs backend support, do not directly revive an old A01-A08 backend branch. Use those branches only as reference/specification, then rebuild the required backend change from the then-current accepted NearMeU base and separately test both consumer and Admin contracts.

Normal work in one repository must not modify files in the other repository automatically. Cross-project changes must be intentional, reviewed and documented.

## 6. RTC provider and credential rule

Agora is the planned RTC provider for Batch09 Audio Calling and Batch10 Video Calling. An Agora project named `NearMeU` has already been created and RTC service is available.

The provider/setup source of truth is `docs/RTC_PROVIDER_AGORA.md`.

Security rules:

- Agora App ID may be used by the client where required, but its exact value does not need to be duplicated in governance documents.
- Agora App Certificate, token-signing secret, REST credentials and equivalent privileged secrets must never be committed to the repository or shipped inside the client.
- production calling must use short-lived server-issued RTC tokens.
- if a privileged Agora credential is exposed or committed, rotate it before production use.
- configured Agora service does not mean Batch09/10 is implemented, accepted, deployed or PASS.

## 7. Admin timing rule

NearMeU-Admin development remains PAUSED while the consumer app completes its launch path.

The planned order after Base08 lock is:

1. Batch09 - Audio Calling (Agora RTC)
2. Batch10 - Video Calling (Agora RTC)
3. Batch11 - Google Play Premium verification
4. Batch12 - Production hardening
5. Batch13 - Play Store Internal / Closed Testing
6. Batch14 - Controlled Public Launch
7. Batch15 - NearMeU Admin full development and integration

Admin may resume only after the consumer public-launch phase is complete and the owner explicitly unlocks Admin work.

## 8. Permanent operating-system rule

These rules are not temporary Base08 instructions. They remain the default NearMeU project/deployment operating system for future batches unless an explicit governance change is reviewed and accepted.

Whenever documents disagree, development and deployment stop until the operating blueprint, official base manifest, project state manifest and this document are reconciled.
