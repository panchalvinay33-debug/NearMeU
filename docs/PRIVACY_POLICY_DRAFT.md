# NearMeU Privacy Policy — publication draft

**Status:** Draft for owner/legal review. Replace every bracketed placeholder before publishing. This file is not a substitute for professional legal advice.

**Effective date:** [EFFECTIVE DATE]

**Service operator:** [LEGAL PERSON OR COMPANY NAME]

**Contact:** [PRIVACY CONTACT EMAIL]

NearMeU is an adults-only social discovery and private-messaging application. This policy explains what information NearMeU processes, why it is processed, how it is protected, and the choices available to users.

## 1. Scope

This policy applies to the NearMeU Android application, its Firebase-backed services, and the public support or deletion pages operated at [PUBLIC WEBSITE DOMAIN].

NearMeU is intended only for people who are at least 18 years old. The service must not be used by children.

## 2. Information processed

### Account and profile information

NearMeU may process:

- Firebase account identifiers and authentication provider information;
- email address where supplied by the authentication provider;
- age and profile details entered by the user;
- profile name, gender and matching preferences;
- profile photos selected by the user;
- account status, suspension status and privacy settings.

### Location and nearby discovery

NearMeU requests device location to provide nearby discovery. The service may process precise device coordinates privately to calculate proximity. Public discovery data is reduced to approximate coordinates and bounded discovery cells. Exact coordinates, email address, city and notification preferences are kept in owner-only private profile data and are not exposed through the public user directory.

Users can deny or revoke location permission in Android settings. Nearby discovery may not function without location access.

### Private messages

NearMeU processes private messages, reply references, delivery/read state, unsend state and per-user deletion state so conversations can operate. Message creation is handled by authenticated backend functions with rate limiting and two-way block checks.

Private message text is not intentionally included in push-notification payloads, Analytics events, Crashlytics custom fields, Performance trace attributes or moderation audit logs.

### Reports, blocks and safety information

When a user reports or blocks another user, NearMeU may process:

- reporter and reported-account identifiers;
- selected report reason and optional description;
- report status and moderator action;
- block relationships;
- anti-abuse counters, cooldowns and privacy-safe audit events.

Anti-abuse counters, report locks and moderation audit records are backend-only and are not readable by normal clients.

### Device, notification and security information

NearMeU may process:

- Firebase Cloud Messaging registration tokens;
- App Check and Play Integrity validation information;
- device/platform information required for notification delivery;
- authentication, security and abuse-prevention signals;
- application version and operational diagnostics.

Raw notification tokens are stored outside public profiles and are removed when invalid, unregistered, logged out or deleted where the cleanup process succeeds.

### Diagnostics, analytics and performance

Production releases may use Firebase Crashlytics, Google Analytics for Firebase and Firebase Performance Monitoring for reliability, product analytics, fraud prevention, diagnostics and performance measurement.

The application telemetry layer rejects common sensitive field names, including email, raw user ID, token, message/text, exact location, address, phone, profile name and photo markers. Telemetry must remain operational and low-cardinality.

Debug and profile builds keep observability collection disabled by default unless an internal tester explicitly opts in.

## 3. Purposes and legal basis

NearMeU processes information to:

- create and secure accounts;
- provide nearby discovery and compatibility filtering;
- deliver private messages and notifications;
- implement blocking, reporting, suspension and account deletion;
- prevent spam, fraud, unauthorized access and abuse;
- diagnose crashes and performance problems;
- comply with legal obligations and valid requests;
- protect users, the service operator and the public.

The operator must insert the legally applicable bases for each purpose before publication, for example contract performance, consent, legitimate interests and legal obligation: [JURISDICTION-SPECIFIC LEGAL BASIS].

## 4. Sharing and service providers

NearMeU does not sell personal information.

Information may be processed by service providers necessary to operate the application, including Google Firebase services such as Authentication, Firestore, Cloud Functions, Cloud Storage, Cloud Messaging, App Check, Crashlytics, Analytics and Performance Monitoring.

Information may also be disclosed:

- when required by applicable law, court order or valid government request;
- to investigate fraud, abuse, security incidents or threats to safety;
- during a legitimate business transfer, subject to appropriate safeguards;
- with the user’s direction or consent.

The operator must publish the final list of processors, applicable transfer safeguards and company/legal contact details before launch.

## 5. Retention

Information is retained only as long as reasonably necessary for the purposes described above, including safety, dispute resolution, fraud prevention, backups and legal obligations.

Suggested owner-reviewed retention schedule before publication:

- active account/profile data: while the account remains active;
- private messages: until removed under product controls, account cleanup or a defined retention policy;
- pending safety reports: until reviewed plus [RETENTION PERIOD];
- moderation and security audit records: [RETENTION PERIOD];
- Crashlytics, Analytics and Performance data: according to the configured Firebase retention settings;
- deletion retry records: until cleanup succeeds or manual remediation is completed.

The final policy must state actual configured periods rather than aspirational periods.

## 6. Account deletion

Users can request account deletion inside NearMeU through **Settings → Delete account**. For Google-authenticated accounts, recent reauthentication may be required before deletion.

The deletion process attempts to remove the Firebase Authentication account and associated public/private profile data, blocks, reports, registered devices and other user-owned records. A backend retry process handles incomplete cleanup. Some information may be retained where required for security, fraud prevention, legal compliance or unresolved disputes.

A public deletion-request page must also be published at [ACCOUNT DELETION URL] before Google Play production submission.

## 7. User choices and rights

Depending on applicable law, users may have rights to access, correct, export, restrict, object to or delete personal information.

Users can:

- edit supported profile details in the application;
- revoke location and notification permission in Android settings;
- disable supported notification preferences;
- block or report another account;
- delete their account in Settings;
- contact [PRIVACY CONTACT EMAIL] regarding a privacy request.

The operator may need to verify identity before fulfilling a request.

## 8. Security

NearMeU uses technical and organizational safeguards including Firebase Authentication, App Check/Play Integrity, server-side callable functions, Firestore security rules, private profile separation, bounded location disclosure, two-way blocking, message/report rate limits, release signing controls and encrypted transport.

No service can guarantee absolute security. Users should use a secure device, protect their account and report suspected unauthorized access.

## 9. Backups and device transfer

The Android application disables application backup and supplies explicit cloud-backup and device-transfer exclusions for private application state. Server-side data remains subject to the operator’s Firebase configuration and retention practices.

## 10. International processing

Firebase and other providers may process information in countries other than the user’s country. Before publication, the operator must state the relevant operating country, processor regions and applicable transfer mechanism: [INTERNATIONAL TRANSFER DETAILS].

## 11. Changes

This policy may be updated when the service, law or processing practices change. Material changes should be communicated through the application, website or another appropriate channel. The effective date at the top will be updated.

## 12. Contact

[LEGAL PERSON OR COMPANY NAME]

[POSTAL ADDRESS]

[PRIVACY CONTACT EMAIL]

[PUBLIC WEBSITE DOMAIN]
