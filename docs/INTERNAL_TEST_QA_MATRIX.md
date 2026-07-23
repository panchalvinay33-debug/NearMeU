# NearMeU internal-test QA matrix

Use this checklist for every Google Play internal-test candidate. Record evidence against the exact version, commit and AAB checksum.

## Release identity

- Version name: [VERSION NAME]
- Version code: [VERSION CODE]
- Git commit: [COMMIT SHA]
- AAB SHA-256: [CHECKSUM]
- Test date: [DATE]
- Tester(s): [NAMES]
- Firebase project: `nearmeu-e82c7`

## Required test setup

Use at least:

- two physical Android devices;
- two different NearMeU test accounts;
- different Android versions where practical;
- one fresh install and one update install;
- synthetic profiles, photos and chat content only.

Do not use personal production data for release testing.

## Severity definitions

- **P0 blocker:** security/privacy exposure, account takeover, deletion failure with unsafe state, widespread crash, broken authentication or message delivery.
- **P1 critical:** major feature unusable, notification loops, location disclosure beyond intended precision, block/report bypass.
- **P2 important:** degraded workflow with workaround, incorrect status, confusing failure handling.
- **P3 minor:** visual/copy issue that does not affect safety or completion.

## Test matrix

| Area | Test | Expected result | Device/account | Result | Evidence/issue |
|---|---|---|---|---|---|
| Install | Install from Play internal-test link | App installs successfully and opens without a debug banner | | | |
| Update | Upgrade from previous internal build | User session/data remain consistent with current migration rules | | | |
| Authentication | Google sign-in with registered certificate | Sign-in succeeds without OAuth/certificate error | | | |
| Authentication | Cancel sign-in | App returns safely with a clear state | | | |
| Onboarding | Submit age below 18 | Adult-only access is refused | | | |
| Onboarding | Complete valid adult profile | Profile is created with normalized gender/preferences | | | |
| Permissions | Deny location | Nearby explains limitation and does not crash | | | |
| Permissions | Grant approximate/precise location as supported | Discovery behaves according to permission and platform | | | |
| Discovery | Select 10/25/50 km radius | Results stay within supported capped radius | | | |
| Discovery | Inspect another profile | No email, exact coordinates or private settings are exposed | | | |
| Compatibility | Test incompatible preferences | Incompatible profiles are excluded | | | |
| Chat | Send first message | Trusted callable creates chat/message successfully | | | |
| Chat | Send messages faster than one second | Server rejects excessive speed cleanly | | | |
| Chat | Exceed 30 messages in one minute | Rate limit activates without data corruption | | | |
| Chat | Reply to a message | Reply metadata renders correctly | | | |
| Chat | Receiver marks message seen | Seen state updates only for receiver | | | |
| Chat | Sender unsends message | Only sender can unsend; conversation summary stays valid | | | |
| Chat | Delete message for me | Message disappears only for requesting participant | | | |
| Chat | Attempt direct client write using test harness/emulator | Firestore rules deny direct chat/message creation | | | |
| Blocking | Account A blocks B | Discovery/chat/message access is blocked both ways | | | |
| Blocking | Unblock | Access returns only where product rules permit | | | |
| Reports | Submit valid report | Report is accepted and reporter can see only own report | | | |
| Reports | Submit duplicate/pending report | Duplicate/cooldown protection responds clearly | | | |
| Reports | Exceed daily report limit | Further report is rejected without exposing counters | | | |
| Notifications | Receive background push | Notification contains no private message text | | | |
| Notifications | Tap push | Correct conversation opens once | | | |
| Notifications | Disable notification preference | Server respects preference | | | |
| Lifecycle | Background app | Presence changes to offline according to lifecycle logic | | | |
| Lifecycle | Resume app | Presence returns without duplicate listeners | | | |
| Suspension | Suspend test account from admin path | User is prevented from active app workflows | | | |
| Logout | Log out | Presence becomes offline and current device token unregisters | | | |
| Account deletion | Delete account after reauthentication | Auth account and covered user data are removed/queued for retry | | | |
| Account deletion | Relaunch after deletion | Deleted account does not regain stale authenticated access | | | |
| App Check | Install from Play and call Functions | Play Integrity token is accepted without rejection loop | | | |
| App Check | Use untrusted client/emulator without valid token | Enforced callable access is denied as configured | | | |
| Privacy | Inspect Analytics/Crashlytics/Performance | No email, UID, exact location, token, profile name/photo or chat text appears | | | |
| Reliability | Cold start repeatedly | No launch crash; startup trace is reasonable | | | |
| Reliability | Network loss during chat/report/delete | UI fails safely and retry/state remains consistent | | | |
| Accessibility | Large font/display scaling | Core controls remain usable and warnings readable | | | |
| Store | Privacy/deletion URLs from listing | Public pages open without authentication | | | |

## Security and privacy spot checks

- [ ] Public user document does not contain email, exact coordinates, city or raw notification settings.
- [ ] Private profile cannot be read by another authenticated user.
- [ ] Device-token documents cannot be enumerated by clients.
- [ ] Anti-abuse counters, report locks and moderation audit logs are client-inaccessible.
- [ ] Push payload contains identifiers/navigation data only, not private message content.
- [ ] Android backup/device-transfer rules exclude app-private state.
- [ ] Cleartext network traffic is disabled.
- [ ] Release build is signed with the intended upload certificate.

## Observability review

After the test session:

- [ ] Crashlytics shows no new P0/P1 crash.
- [ ] Non-fatal errors are understandable and contain no private content.
- [ ] Analytics events remain low-cardinality and operational.
- [ ] Performance traces have safe names/attributes.
- [ ] No test credentials or synthetic chat text appear in dashboards.

## Exit criteria

A candidate may move from internal to closed testing only when:

- all P0 and P1 issues are resolved and retested;
- authentication, discovery, chat, notifications, blocking, reports and deletion pass on both devices;
- App Check works on Play-installed builds;
- no private data is found in public Firestore paths, notifications or telemetry;
- the AAB checksum, commit, version and symbol archive are retained;
- the privacy policy, deletion page and Play declarations match the tested build.

## Sign-off

- Engineering: [NAME / DATE]
- Privacy/safety review: [NAME / DATE]
- Product owner: [NAME / DATE]
- Promotion decision: [INTERNAL → CLOSED / HOLD]
