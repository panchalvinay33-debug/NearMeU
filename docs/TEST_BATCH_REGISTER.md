# NearMeU Test Batch Register

Last updated: 2026-08-08

Authoritative stability/recovery rules: `docs/ANDROID_STABILITY_AND_RECOVERY_RULEBOOK.md`.

Physical acceptance requires a signed artifact, checksum, device evidence, owner decision, GitHub recovery point and verified PC full-source backup. Deferred evidence must remain explicitly marked as deferred and must never be rewritten as PASS.

## Batch table

| Batch | Title | Historical status | Current development status |
|---|---|---|---|
| 00 | Governance, roadmap and decision freeze | ACCEPTED | Historical foundation |
| 01 | Chat reliability and message-state truth | ACCEPTED | Superseded |
| 02 | Photo/video/voice-message reliability | ACCEPTED | Superseded |
| 03 | Local-first persistence and seven-day delivery cloud | ACCEPTED | Superseded |
| 04 | Clear Chat and deletion semantics | ACCEPTED | Superseded |
| 05 | Identity, account close and reactivation | ACCEPTED | Superseded |
| 06 | Premium entitlement foundation | ACCEPTED | Superseded by Batch 07 |
| 07 | Six-month automatic Premium backup and restore | ACCEPTED | Trusted historical baseline |
| 08 | Profile sharing and deep-link recovery | ACCEPTED historically | **Current recovery validation anchor** |
| 08.1 | Device compatibility/network hardening | Previously accepted | **Removed from active development path; reference only** |
| 09 | Agora audio calling | WIP / not accepted | **FROZEN; do not merge** |
| 10 | Agora video calling | PLANNED | Blocked until audio stable |
| 11 | Owner-only Premium administration | PLANNED | Paused |
| 12 | Full regression and Play Store readiness | PLANNED | Later release gate |

## Original Batch 08 recovery anchor

```text
Batch ID: 08
Title: Profile sharing and deep-link recovery
Historical owner status: ACCEPTED
Pull request: #100
Tested runtime commit: fdc9b22322a96b793fff3058b1ca990f656e80a1
Merged runtime commit: f83a6e92457f728f177dc062dcc9171c141a9217
Version: 1.0.11+12
Android package: com.nearmeu.nearmeu
Recovery validation branch: recovery/original-batch08-android-stable
Calling code included: NO
Batch 08.1 included: NO
Current recovery status: REVALIDATION REQUIRED BEFORE NEW PROMOTION
```

Historical Batch 08 acceptance remains evidence of what was tested in 2026-08-02. It does not automatically prove compatibility with the current deployed backend or current test environment after later App Check/functions/Batch09 changes. The recovered base must therefore be revalidated end-to-end.

## Mandatory revalidation matrix

Before the recovered base can be promoted:

- intended Google sign-in entry path on fresh app state;
- existing Google account/profile recognition;
- new-user profile creation only after authentication;
- Nearby/location permission behavior;
- presence lifecycle;
- text send/receive/read state;
- photo/video/voice messaging;
- Clear Chat;
- Delete for Me;
- Delete for Everyone/Unsend;
- Premium/recovery smoke;
- notifications and notification tap;
- foreground/background/resume;
- process kill/reopen;
- Wi-Fi, mobile data, network switching and weak-network handling;
- logout/login;
- reboot/reopen;
- representative Samsung and Motorola physical tests as generic Android evidence.

One unexplained FAIL stops promotion.

## Stable-base PC backup gate

Every future owner-accepted stable base must have a verified PC recovery package under:

`F:\NearMeU_Stable_Backups`

The package must contain complete source with `.git`, accepted signed artifact(s), SHA-256 records, base metadata, Firebase-state notes without secrets, physical-test evidence and exact restore commands. The source archive must be test-extracted and its expected commit verified before the next feature batch begins.

Previous stable backups must not be deleted when a newer stable base is promoted.

## Batch 07 historical evidence note

Batch 07 remains a trusted historical functional baseline. Its receiver-media pre-download/post-download Premium recovery eligibility check remains OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS.

## Current gate

Current work is recovery/stability only. Batch 09 remains frozen until the original Batch 08-derived recovered state passes backend compatibility audit, automated checks, full physical regression, owner acceptance and the mandatory GitHub + PC recovery backup gates.
