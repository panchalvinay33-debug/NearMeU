# NearMeU Google Play internal test plan

Run this plan using a Play-installed build, not a locally sideloaded debug APK. Use at least two physical Android devices and two synthetic adult test accounts.

## Test record

- App version:
- Version code:
- Commit SHA:
- AAB SHA-256:
- Play track:
- Test date:
- Tester:
- Device A / Android version:
- Device B / Android version:
- Firebase project:
- App Check enforcement state:

## Test data rules

- Use synthetic names and messages.
- Use profile photos you own or have permission to use.
- Do not use real private report content.
- Never place passwords, OTPs, tokens, financial data, government IDs, exact addresses, or health information in the test accounts.
- Delete both test accounts after validation when they are no longer needed.

## P0 launch-blocking tests

| ID | Scenario | Steps | Expected result | Result |
|---|---|---|---|---|
| P0-01 | Fresh Google sign-in | Install from Play, open app, sign in with Google | Authentication succeeds with Play signing certificate | ☐ |
| P0-02 | Adult onboarding | Complete nickname, age 18+, gender and looking-for fields | Profile is created; under-18 value is rejected | ☐ |
| P0-03 | Location permission | Grant foreground location while using app | Nearby discovery loads without requesting background location | ☐ |
| P0-04 | Location denial | Deny location permission | App remains stable and explains that nearby discovery is unavailable | ☐ |
| P0-05 | Play Integrity App Check | Use Play-installed build with enforcement enabled | Firestore, Storage and callable Functions work without rejection loops | ☐ |
| P0-06 | Nearby privacy | Compare discovery profile and backend/private view | Other user never receives exact coordinates or private city/email | ☐ |
| P0-07 | Send message | Account A messages B | Message is delivered once and unread count updates | ☐ |
| P0-08 | Notification privacy | B is backgrounded; A sends a message | Push opens correct chat and contains no private message text | ☐ |
| P0-09 | Block enforcement | B blocks A; A attempts discovery/chat | Two-way discovery and messaging are unavailable | ☐ |
| P0-10 | Report flow | A reports B with a synthetic reason | Report is accepted once; duplicate/cooldown controls work | ☐ |
| P0-11 | In-app account deletion | Re-authenticate and delete Account A | Auth account and associated profile data are removed; app returns to sign-in | ☐ |
| P0-12 | Post-deletion privacy | Inspect Account B conversation and backend | Deleted account cannot sign in; messages are hidden for deleted account; other participant behavior matches policy | ☐ |
| P0-13 | External deletion page | Open public URL without the app | Page loads, names NearMeU, and provides a monitored request pathway | ☐ |
| P0-14 | Privacy policy URL | Open public policy URL | Page loads without login and matches production data practices | ☐ |
| P0-15 | Crash-free startup | Cold-start app repeatedly on both devices | No launch crash, ANR, or infinite loading loop | ☐ |

## Messaging and presence

| ID | Scenario | Expected result | Result |
|---|---|---|---|
| MSG-01 | Reply to a message | Reply metadata and quoted preview are correct | ☐ |
| MSG-02 | Seen status | Only receiver marks message seen | ☐ |
| MSG-03 | Sender unsend | Content becomes unavailable without timestamp/sender tampering | ☐ |
| MSG-04 | Delete for me | Message disappears only for requesting participant | ☐ |
| MSG-05 | Rapid send under 1 second | Trusted backend rejects excessive pace gracefully | ☐ |
| MSG-06 | More than 30 messages/minute | Rate limit activates without duplicate writes | ☐ |
| MSG-07 | App background | Presence becomes offline/background-safe | ☐ |
| MSG-08 | Logout | Current device token is unregistered and presence becomes offline | ☐ |
| MSG-09 | Relaunch | Existing chat history loads newest-first without duplicates | ☐ |

## Discovery and profile

| ID | Scenario | Expected result | Result |
|---|---|---|---|
| DIS-01 | 10 km filter | Only compatible profiles within selected range are presented | ☐ |
| DIS-02 | 25 km default | Default distance is 25 km | ☐ |
| DIS-03 | 50 km cap | User cannot query beyond 50 km | ☐ |
| DIS-04 | Compatibility | Gender/looking-for compatibility is mutual | ☐ |
| DIS-05 | Profile photo update | New photo uploads and appears; old data does not leak | ☐ |
| DIS-06 | Suspended profile | Suspended user cannot discover, message, report, or remain online | ☐ |
| DIS-07 | Exact location privacy | Exact coordinates remain owner-only | ☐ |

## Reports and abuse controls

| ID | Scenario | Expected result | Result |
|---|---|---|---|
| SAFE-01 | Self-report attempt | Rejected | ☐ |
| SAFE-02 | Duplicate pending report | Rejected without creating multiple moderation items | ☐ |
| SAFE-03 | More than 5 reports/day | Trusted report rate limit activates | ☐ |
| SAFE-04 | Seven-day repeat cooldown | Repeat report is rejected during cooldown | ☐ |
| SAFE-05 | Client audit access | Client cannot read or write counters, locks, or audit logs | ☐ |
| SAFE-06 | Deleted-user cleanup | Anti-abuse counters, locks, audit logs and profile photo are removed | ☐ |

## Notifications

| ID | Scenario | Expected result | Result |
|---|---|---|---|
| NOT-01 | Permission granted | Message push is delivered | ☐ |
| NOT-02 | Permission denied | App remains usable without notification loop | ☐ |
| NOT-03 | Notifications disabled in app | Backend does not send private chat push | ☐ |
| NOT-04 | Invalid/old token | Invalid token is automatically removed | ☐ |
| NOT-05 | Multiple devices | Valid registered devices receive one appropriate notification each | ☐ |

## Observability and privacy

| ID | Scenario | Expected result | Result |
|---|---|---|---|
| OBS-01 | Controlled non-fatal | Appears in Crashlytics for release/internal build | ☐ |
| OBS-02 | Navigation event | Privacy-safe route event appears in Analytics | ☐ |
| OBS-03 | Startup trace | Performance trace appears | ☐ |
| OBS-04 | Telemetry inspection | No email, raw UID, exact location, token, profile name/photo, report description, or chat text appears | ☐ |
| OBS-05 | Debug build | Telemetry remains off unless explicit internal opt-in is used | ☐ |

## Store and policy validation

- [ ] App title, short description and full description match the current build.
- [ ] Screenshots show only current UI and synthetic data.
- [ ] Privacy policy URL and deletion URL are publicly reachable.
- [ ] Data Safety answers match the exact AAB and Firebase SDK configuration.
- [ ] Content rating reflects user-generated profiles and private chat.
- [ ] Target audience excludes minors.
- [ ] Ads declaration is `No` for V1.
- [ ] App access instructions explain Google sign-in and two-account chat testing.
- [ ] Support email is monitored.
- [ ] Release notes match the uploaded version.

## Exit criteria

Internal testing passes only when:

- every P0 test passes;
- no unresolved crash, ANR, authentication failure, App Check rejection loop, privacy leak, message-loss issue, or deletion failure remains;
- Crashlytics and Performance data are stable enough to assess;
- the Play listing and Data Safety form match observed behavior;
- the test record includes version, commit, AAB checksum, devices, accounts, and results.
