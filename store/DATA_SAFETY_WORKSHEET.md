# NearMeU Google Play Data safety worksheet

**Purpose:** Owner/legal preparation worksheet. Google Play Console questions and terminology can change. Verify every answer against the exact release build and current Play Console before submission.

## Product identity

- Package: `com.nearmeu.nearmeu`
- Firebase project: `nearmeu-e82c7`
- Audience: adults 18+
- Ads in shipping build: [YES / NO]
- Public privacy policy URL: [PRIVACY POLICY URL]
- Public account deletion URL: [ACCOUNT DELETION URL]
- Support contact: [SUPPORT CONTACT]

## Data handling summary

NearMeU uses account/profile data, location for nearby discovery, private messages, user-generated photos, notification tokens, reports/blocks, security signals and operational diagnostics. Exact declarations depend on Google Play’s current taxonomy and the final Firebase/Android configuration.

## Category worksheet

| Data type | Collected? | Shared? | Purpose | Required/optional | Encryption/handling notes | Final answer |
|---|---:|---:|---|---|---|---|
| Email address | Yes, when supplied by auth provider | With service processors | Account management, authentication, security | Required for applicable sign-in method | Owner-only private profile/auth systems; not public directory | |
| User IDs | Yes | With service processors | Account, messaging, security, fraud prevention | Required | Raw IDs must not be sent in custom telemetry fields | |
| Name/profile display name | User supplied | Displayed to compatible users; processors | App functionality/social discovery | Required/optional per onboarding | Public profile field; telemetry policy blocks profile-name parameters | |
| Age | User supplied | Displayed/processed as configured | Adult eligibility, compatibility | Required | Must reject users below 18 | |
| Gender/preferences | User supplied | Displayed/processed for matching | App functionality/personalization | Required/optional per product | Normalize values; do not broaden visibility unexpectedly | |
| Profile photos | User supplied | Displayed to compatible users; storage processor | App functionality/social discovery | Optional or required per onboarding | Use synthetic media in testing | |
| Precise location | Yes when permission granted | Service processors; not intended for public display | Nearby discovery, fraud/security where applicable | Required for nearby feature | Exact coordinates stored privately; public data rounded/approximated | |
| Approximate location | Derived/displayed | Compatible users/processors | Nearby discovery | Required for nearby feature | Bounded discovery cells and rounded public coordinates | |
| Private messages | Yes | Recipient and service processors | Private messaging, safety, delivery | Optional user-generated | Not in push text, Analytics fields or moderation audit logs | |
| Report descriptions | Yes when user submits | Moderators/processors | Safety, fraud prevention, moderation | Optional | Must not enter operational telemetry | |
| Block relationships | Yes | Service processors | Safety and access control | Optional | Private per-user records | |
| Device/notification tokens | Yes | Firebase processors | Notifications, security | Optional feature support | Backend-only/private; unregister on logout/deletion where possible | |
| App interactions | Yes in release telemetry | Firebase Analytics processor | Analytics, product improvement | Operational collection | Low-cardinality; sensitive-key filter | |
| Crash logs | Yes in release telemetry | Firebase Crashlytics processor | Diagnostics, reliability | Operational collection | No intentional message text, email, raw UID, exact location or tokens | |
| Performance data | Yes in release telemetry | Firebase Performance processor | Performance and reliability | Operational collection | Safe trace names/attributes only | |
| Security/App Check signals | Yes | Google/Firebase processors | Fraud prevention, security | Required for protected services | Play Integrity/App Check enforcement | |

## Sharing interpretation review

Before answering “shared,” determine how current Play policy treats processing by service providers acting on the operator’s behalf. Do not assume that every processor transfer is classified identically. Document the reasoning and current Play wording used for each answer.

## Collection and deletion checks

- [ ] In-app deletion path is reachable from Settings.
- [ ] Public deletion page is reachable without login.
- [ ] Deletion description matches actual backend cleanup and retry behaviour.
- [ ] Privacy policy lists Firebase services actually enabled.
- [ ] Retention periods reflect configured practice.
- [ ] Location wording distinguishes precise private processing from approximate public discovery.
- [ ] Private messages and report descriptions are disclosed accurately.
- [ ] Diagnostics/analytics/performance collection matches release-enabled and debug-default-off behaviour.
- [ ] Ads declaration matches dependencies and runtime behaviour.
- [ ] Children/target-audience answers match 18+ onboarding enforcement.

## Security practices worksheet

- Data encrypted in transit: expected through Firebase/HTTPS; verify final endpoints.
- User deletion request mechanism: in-app plus public assisted-request page.
- Independent security review: [YES / NO / PLANNED].
- Account creation: authenticated provider flow.
- Account deletion: authenticated confirmation and recent reauthentication where required.
- Backup policy: Android backup and device transfer explicitly excluded for app-private state.

## Evidence to retain

- Screenshot/PDF export of submitted Data safety answers.
- Privacy-policy version and effective date.
- Account-deletion page version.
- Release commit SHA and AAB checksum.
- Firebase product/configuration list.
- Current Android manifest permissions.
- QA evidence proving no private content in notifications or telemetry.
- Date and reviewer who approved each declaration.

## Approval

- Engineering verification: [NAME / DATE]
- Privacy/legal verification: [NAME / DATE]
- Product owner approval: [NAME / DATE]
- Play Console submission date: [DATE]
