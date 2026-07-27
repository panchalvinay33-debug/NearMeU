# NearMeU — Production Deployment Record

Date: 2026-07-27
Firebase project: `nearmeu-e82c7`
Source branch: `ops/pre-test-readiness-v1`

## Completed

- Firebase Hosting deployed successfully.
- Public homepage: `https://nearmeu-e82c7.web.app/`
- Privacy Policy: `https://nearmeu-e82c7.web.app/privacy/`
- Account deletion page: `https://nearmeu-e82c7.web.app/delete-account/`
- Firestore security rules deployed.
- Firestore indexes deployed.
- Firebase Storage rules deployed.
- Cloud Functions deployed in `asia-south1`.
- Support email confirmed as `supportnearmeu@gmail.com`.
- Pre-test readiness checks passed on the owner's Windows PC.
- GitHub quality gate run 271 completed successfully for commit `c3138689f7f89b1a665af687be20301a51702d35`.

## Intentionally pending

- Physical two-account/two-device acceptance testing.
- App Check enforcement after test-device registration and validation.
- Release keystore creation and encrypted backup.
- Signed Android App Bundle generation.
- Play Console closed testing and production rollout.
- Managed Firestore export bucket and automated backup schedule.
- Project-state manifest write to Firestore. This is non-blocking housekeeping and requires local Application Default Credentials.

## Notes

The Firebase deployment itself completed successfully. The later project-state manifest helper failed because Google Cloud Application Default Credentials were not installed on the operator PC. No deployed rules, indexes, Storage rules, Hosting release, or Cloud Functions were rolled back by that helper failure.

This record contains no credentials, passwords, service-account keys, keystores, or private user data.
