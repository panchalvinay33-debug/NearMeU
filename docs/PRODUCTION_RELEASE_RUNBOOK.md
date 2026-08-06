# NearMeU Production Deployment and Release Runbook

Last updated: 2026-08-06

This runbook defines the only supported path from accepted/reviewed NearMeU source to Firebase production and later Google Play distribution.

## 1. Absolute rule

Never deploy production Firebase resources and never build a production-distribution artifact from an unmerged feature branch.

Production deployment source must be:

- branch `main`;
- clean working tree;
- exact match to `origin/main`;
- reviewed/merged source;
- applicable CI green;
- correct package/project/version identity.

Before deployment:

```powershell
cd F:\NearMeU
.\tool\verify_deployment_gate.ps1
```

If this gate fails, do not deploy.

## 2. Project identity

- Repository: `panchalvinay33-debug/NearMeU`
- Canonical PC workspace: `F:\NearMeU`
- Firebase project: `nearmeu-e82c7`
- Android package: `com.nearmeu.nearmeu`
- Version source: `pubspec.yaml`
- Permanent signing identity: protected GitHub signing secrets; certificate fingerprint recorded in `config/official_base_manifest.json`

## 3. Version rule

`pubspec.yaml` is the single source:

```yaml
version: X.Y.Z+N
```

- `X.Y.Z` → Android versionName.
- `N` → Android versionCode.
- Every Google Play upload must use a versionCode greater than every previously uploaded build.
- Never hardcode versionName/versionCode independently in Android Gradle configuration.
- About screen must display runtime package information, not a hardcoded version string.

## 4. Required pre-deploy gates

Applicable candidate checks must pass:

- formatter;
- Flutter analyze/compile checks;
- Flutter tests;
- Firebase Rules emulator tests;
- Cloud Functions tests/module load;
- signed APK/release build gates as applicable;
- permanent signing certificate verification.

Also verify:

- all intended PRs are merged;
- no known launch-blocking fix remains open;
- local `F:\NearMeU` matches `origin/main`;
- the batch has owner authorization to deploy;
- `config/official_base_manifest.json` and `docs/PROJECT_OPERATING_BLUEPRINT.md` describe the correct project identity.

## 5. Synchronize the deployment PC

```powershell
cd F:\NearMeU
git fetch --prune origin
git switch main
git reset --hard origin/main
.\tool\verify_deployment_gate.ps1
```

Do not deploy from a Downloads clone, old backup folder or detached experimental SHA.

## 6. Validate dependencies before Firebase deployment

```powershell
npm ci --prefix functions --no-audit --no-fund
npm test --prefix functions
flutter pub get
flutter test
```

## 7. Firebase deployment order

Use the smallest targeted deploy that safely implements the accepted change.

When a batch changes the full Firebase stack, use this order:

```powershell
firebase deploy --only firestore:indexes,firestore:rules --project nearmeu-e82c7
firebase deploy --only storage --project nearmeu-e82c7
firebase deploy --only functions --project nearmeu-e82c7
```

Deploy Hosting only when the accepted batch changes Hosting:

```powershell
firebase deploy --only hosting --project nearmeu-e82c7
```

Why this order:

1. required indexes/rules become available first;
2. Storage policy is updated before functions rely on it;
3. Functions receive traffic only after their data/security prerequisites exist;
4. Hosting is independent and deployed only when necessary.

Do not use a stale local `firestore.indexes.json`. Always synchronize `main` first.

## 8. Console-only configuration prohibition

Repository-managed Firestore rules, indexes and Storage rules must not live only in Firebase Console.

CLI deployment can overwrite console edits. Permanent project truth belongs in source control.

Emergency console actions must be reflected back into accepted source before closeout.

## 9. Post-deploy production audit

Immediately after deployment:

```powershell
.\tool\audit_production_state.ps1
```

The audit compares deployed Cloud Functions against accepted `functions/bootstrap.js` exports.

Unexpected deployed Functions are production drift and block acceptance/promotion.

Examples:

- abandoned Admin function;
- old calling function;
- function deployed from a feature branch;
- function removed from accepted source but still running in Firebase.

Resolve drift before declaring the batch closed.

## 10. Firestore/index verification

After index/rule changes:

- confirm required indexes are enabled/ready;
- confirm no stale custom field exemption breaks normal automatic collection indexes;
- exercise the affected query physically;
- never mark a query defect fixed solely because the deployment command succeeded.

## 11. App Check

Debug physical testing may use installation-specific App Check debug tokens.

Production/Play builds must use the approved production provider (Play Integrity where configured) and correct certificate fingerprints.

Never commit App Check debug tokens.

## 12. Android signed artifacts

Permanent signing secrets live in protected GitHub secrets/environment, not the repository.

Retain:

- artifact ID;
- artifact digest;
- APK/AAB SHA-256;
- exact Git source/merge-ref;
- signing certificate fingerprint;
- workflow run ID.

A physical acceptance is valid only for the exact artifact that was tested.

## 13. Google Play path

Do not promote the first successful build directly to production.

Recommended release path:

1. internal testing;
2. two-device physical acceptance from Play-distributed build;
3. closed testing;
4. gradual production rollout;
5. monitor crashes/ANRs/auth/message delivery/functions/App Check/storage/retention/deletion.

If Play rejects a release, fix the issue, increment versionCode, rebuild through the controlled workflow, and preserve traceability to the exact Git SHA.

## 14. Production rollback / base recovery

Source rollback:

```powershell
cd F:\NearMeU
.\tool\restore_official_base.ps1
```

Then audit deployed functions:

```powershell
.\tool\audit_production_state.ps1
```

Source recovery does not automatically delete deployed functions. Resolve only confirmed production drift and redeploy accepted resources if required.

Never delete user data merely to return source/backend code to an accepted base.

## 15. Acceptance/promotion rule

A production-changing batch cannot become official recovery truth until:

- exact candidate CI PASS;
- signing PASS;
- owner physical acceptance PASS;
- production deploy PASS;
- production-state audit PASS;
- docs/manifest updated;
- recovery branch promoted;
- canonical local workspace synchronized.

The full governing process is defined in `docs/PROJECT_OPERATING_BLUEPRINT.md`.
