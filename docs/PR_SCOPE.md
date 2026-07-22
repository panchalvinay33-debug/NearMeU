# Pull request scope

This branch is intentionally a draft release-hardening branch. It is based on the latest `main` and must remain free of unrelated visual redesign or V2 feature work.

The branch may include only production blockers identified in the NearMeU audit: onboarding/data consistency, adult eligibility, Nearby compatibility, privacy/security rules, chat integrity and pagination, lifecycle presence, FCM backend delivery, account deletion, legal acceptance, moderation auditability, CI, secure signing, and release documentation.

Every subsystem change must include automated tests or a documented manual staging check. The branch remains draft until all required checks pass.
