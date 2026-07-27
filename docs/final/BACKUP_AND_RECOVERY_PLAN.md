# NearMeU — Backup and Recovery Plan

## Objectives

Protect source code, Firestore data, Firebase Storage media, Firebase configuration and Android signing material. A backup is considered valid only when restoration has been tested.

## Current operational status — 2026-07-27

Completed:

- Source code is stored in GitHub and on the owner's PC.
- Firebase Hosting, Firestore rules/indexes, Storage rules and Cloud Functions have been deployed to `nearmeu-e82c7`.
- Public legal/support pages are live.
- The exact deployment record is stored in `docs/final/PRODUCTION_DEPLOYMENT_RECORD_2026-07-27.md`.
- Firebase project mapping is versioned in `.firebaserc`.

Still required before public launch:

- Merge the release-readiness branch into `main` and create a protected release tag.
- Create a private Firestore export bucket and perform the first verified export.
- Configure Storage backup/versioning or an equivalent controlled copy process.
- Create the Android release keystore and store encrypted copies in two secure locations.
- Test restoration into a staging project.

## 1. Source-code backup

Primary copy:

- GitHub repository and protected release branch/tag.

Additional copies:

- Local clone on the owner's computer.
- Periodic encrypted repository bundle or ZIP stored outside that computer.
- Release documentation and machine-readable manifest committed with the code.

Recommended release freeze:

```bash
git checkout main
git pull --ff-only
git tag -a nearmeu-pretest-production-baseline-2026-07-27 -m "NearMeU pre-test production baseline"
git push origin nearmeu-pretest-production-baseline-2026-07-27
```

Do not store service-account keys, keystores, passwords or `.env` secrets in Git.

## 2. Firestore backup

### Production method

Use managed Firestore export to a dedicated Google Cloud Storage backup bucket in the same controlled organization/project boundary.

Example manual export:

```bash
gcloud firestore export gs://YOUR_BACKUP_BUCKET/firestore/manual-$(date +%Y-%m-%d)
```

Recommended schedule:

- Daily automated export retained for 14 days.
- Weekly export retained for 8 weeks.
- Monthly export retained for 12 months.
- Manual export immediately before rules/schema migrations and major releases.

Security requirements:

- Bucket must not be public.
- Enable uniform bucket-level access.
- Limit restore/export IAM to administrators.
- Use retention/lifecycle rules deliberately.
- Prefer a separate backup bucket and, where feasible, a separate backup project.

### Restore procedure

1. Stop or restrict writes if restoring over an active production system.
2. Record the incident time and select the last known-good export.
3. Export the damaged current state before restoration for forensic recovery.
4. Import into a staging Firebase/GCP project first.
5. Verify users, chats, messages, blocks, reports, announcements and system configuration.
6. Import to production only after approval.
7. Re-enable writes gradually and monitor errors.

Example import:

```bash
gcloud firestore import gs://YOUR_BACKUP_BUCKET/firestore/EXPORT_FOLDER
```

Firestore export/import does not replace Firebase Authentication, Storage or signing backups; those are separate.

## 3. Firebase Storage backup

Private chat and announcement media require an independent bucket-copy strategy.

Recommended method:

- Enable object versioning when cost permits.
- Use scheduled Storage Transfer Service or controlled `gcloud storage rsync` to a private backup bucket.
- Apply lifecycle policies compatible with product deletion/retention promises.

Example controlled copy:

```bash
gcloud storage rsync --recursive gs://YOUR_APP_BUCKET gs://YOUR_MEDIA_BACKUP_BUCKET
```

Do not restore deleted user content blindly. Account-deletion and retention obligations take precedence; backup retention must be documented in the Privacy Policy and operational process.

## 4. Firebase Authentication recovery

- Preserve authentication provider configuration and authorized domains as screenshots/exported operational records.
- Restrict service-account access.
- For migrations, use official Firebase Auth export/import tools where supported and legally appropriate.
- Never commit exported password hashes or private user data to Git.

## 5. Configuration backup

Keep versioned copies of:

- `firebase.json`
- `.firebaserc` without secrets
- Firestore rules and indexes
- Storage rules
- Cloud Functions source and dependency lockfiles
- Android manifest/Gradle configuration
- Public policy text
- Play Console declarations and release notes as private operational records
- Dated production deployment records under `docs/final/`

Remote Console-only settings must be documented after every production change.

## 6. Android signing-key backup

The Play upload/release keystore is critical and must be backed up separately.

Store encrypted copies in at least two secure locations:

- Password manager/secure vault attachment or enterprise secret vault.
- Offline encrypted drive held separately.

Also preserve:

- Keystore alias
- Store password
- Key password
- SHA-1 and SHA-256 certificates
- Play App Signing status

Never commit signing files or passwords to GitHub.

## 7. Recovery priorities

### Priority 1 — Security incident

- Disable compromised credentials/tokens.
- Restrict writes and deploy safe rules.
- Preserve logs and current-state export.
- Rotate secrets and verify App Check/signing integrity.

### Priority 2 — Data corruption

- Stop the damaging writer/function.
- Export current state.
- Restore last known-good data in staging.
- Reconcile legitimate records created after the backup where possible.

### Priority 3 — Bad app release

- Halt rollout in Play Console.
- Return to previous stable release or issue a corrected build.
- Do not force-update users to another unverified build.

### Priority 4 — Cloud Function failure

- Roll back to the last known-good function source/tag.
- Disable only the failing trigger where possible.
- Check idempotency before replaying events.

## 8. Backup verification checklist

Run at least monthly and before public launch:

- [ ] Latest Firestore export exists and is readable.
- [ ] Storage backup job completed without unexpected deletions.
- [ ] Restore into staging succeeds.
- [ ] Sample users, chats, messages and announcements are correct.
- [ ] Private media remains private after restore.
- [x] Rules and indexes deploy cleanly.
- [ ] Signing-key encrypted backup is accessible to the owner.
- [ ] Recovery contacts and access permissions are current.
- [ ] Backup cost and retention are within budget.
- [x] Production deployment record is committed with the source.

## 9. Recovery point and recovery time targets

Initial small-launch targets:

- Firestore RPO: 24 hours maximum, improved with more frequent exports when usage grows.
- Storage RPO: 24 hours maximum for retained media.
- Core service RTO: 4–8 hours for an administrator-led recovery.

These targets should be tightened after production usage and revenue justify stronger automation.
