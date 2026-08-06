# NearMeU Future Roadmap

Status: PLANNING ONLY — LOCKED until Base08 final closeout and explicit owner unlock
Last updated: 2026-08-06

This roadmap defines the safest order for work after the official Base08 recovery state. It is planning only. No future batch may start from old Batch09/Admin experiment branches; every batch must start from the then-current official recoverable base.

## Non-negotiable operating rule

Every future runtime batch must follow:

`Select one scope → freeze it → branch from official immutable base → code → CI → permanently signed APK → focused physical test → owner PASS → merge → deploy exact main SHA if required → production-state audit → docs/evidence → immutable acceptance tag → recovery promotion → offline bundle → local sync → delete/neutralize temporary branch → unlock next batch`

If any gate fails, stop. Fix or abandon that batch without moving the official recovery base.

## Entry condition for any future batch

Before Batch09 or later can start, all must be true:

- Base08 final closeout is complete;
- `main`, `stable/official-recoverable-base` and immutable Base08 tag identify the same accepted source state;
- offline Git bundle/hash exists;
- canonical PC workspace `F:\NearMeU` is synchronized;
- production Firebase audit shows no unexplained post-Base08 drift;
- temporary cleanup branches/PRs are closed/removed or neutralized;
- owner explicitly says to unlock the next batch.

## Batch 09 — Audio calling foundation

Goal: add reliable one-to-one audio calling without changing accepted chat/media/Premium/recovery behavior.

### Scope

- one-to-one audio call initiation and receive flow;
- trusted backend authorization;
- server-issued short-lived call credentials/tokens;
- ringing, accept, decline, cancel, end, timeout and missed-call lifecycle;
- microphone permission handling;
- mute and speaker controls;
- Premium initiation policy only if explicitly approved before coding;
- no recording of call audio;
- no call media stored in Premium recovery.

### Forbidden scope

- video calling;
- call-history UI until core audio is physically accepted;
- owner Admin dashboard;
- Google Play purchase verification;
- unrelated Nearby/chat redesign.

### Acceptance matrix

- A calls B and B receives while foreground;
- B calls A;
- accept/decline/cancel/end;
- caller/callee app background/foreground transitions;
- network loss/reconnect/failure state;
- blocked/suspended/inactive users cannot bypass policy;
- no duplicate simultaneous call session;
- Nearby/Chats/text/photo/video/voice-message smoke PASS;
- uninstall is not used for normal upgrade testing.

### Deployment

Deploy only the exact reviewed `main` functions/config required for calling, then run production drift audit.

### Exit condition

Audio calling becomes a new official recoverable base only after two-device physical PASS and owner acceptance.

## Batch 10 — Video calling

Dependency: Batch09 audio calling must already be accepted and promoted.

### Scope

- one-to-one video upgrade/new video call flow;
- camera permission and camera on/off;
- front/back camera switch;
- speaker/mute behavior inherited from accepted audio foundation;
- video connection/failure/cleanup lifecycle.

### Forbidden scope

- group calls;
- call recording;
- filters/effects;
- Admin/billing work.

### Acceptance matrix

Two-device bidirectional video calls, permission denial/retry, camera switching, background/foreground, network loss, hangup cleanup, audio-only regression, chat/media regression.

## Batch 11 — Google Play Premium purchase verification

Dependency: calling capabilities and existing Premium entitlement model are stable.

### Scope

- Google Play Billing integration;
- server-side purchase verification;
- idempotent entitlement grant/update;
- expiry/cancellation/refund handling;
- restore purchases;
- single source of Premium truth remains backend-controlled;
- preserve admin-grant independence if owner grants remain supported.

### Forbidden scope

- changing Premium price/plan without explicit owner decision;
- trusting client-only purchase state;
- broad Admin dashboard work.

### Acceptance matrix

Internal-test purchase, restore on second install/device, expiry/cancel/refund simulation where supported, duplicate callback/idempotency, Free fallback, calling/media entitlement regression.

## Batch 12 — Owner control and safe administration

Dependency: production entitlement contracts must already be stable.

### Scope

Build owner-only administration in small sub-batches, each separately accepted. Candidate modules:

1. owner session/authorization;
2. users/account-state view;
3. Premium grant/revoke controls;
4. reports/moderation workflow;
5. messaging/recovery/system health read-only diagnostics;
6. audit log.

### Safety rules

- server-authoritative owner/admin claims;
- App Check enforced;
- least privilege;
- every mutation audited;
- no broad message-content access by default;
- no Admin function is deployed until its exact UI/use-case batch is approved;
- each Admin sub-batch can be rolled back independently.

## Batch 13 — Production hardening and observability

### Scope

- production App Check / Play Integrity validation;
- Crashlytics, Analytics and Performance verification with privacy-safe telemetry;
- FCM production validation;
- scheduled function health;
- Firestore/Storage/index drift audit;
- account deletion and retention production checks;
- privacy policy / terms / data-safety mapping;
- abuse/rate-limit review;
- dependency/security update review with regression testing.

No major product feature is added in this batch.

## Batch 14 — Play internal and closed testing

### Scope

- build signed AAB from exact accepted `main`;
- increment versionCode correctly;
- upload to Play Internal Testing;
- install Play-distributed build on at least two physical Android devices/accounts;
- full regression matrix;
- verify Play Integrity/App Check;
- resolve launch-blocking issues through separate stabilization PRs;
- move to Closed Testing only after internal acceptance.

### Full regression areas

Authentication/onboarding, Nearby, presence, Chats, sent/delivered/read states, text/reply/emoji, photo/video/voice messages, local-first history, seven-day delivery cloud, Clear/Delete/Unsend, account close/reactivation/deletion, Premium, recovery, profile sharing/deep links, audio/video calls, billing, notifications and owner controls as applicable.

## Batch 15 — Controlled production launch

Dependency: closed testing is accepted and no launch blocker remains.

### Scope

- final Play declarations/assets;
- staged production rollout, not instant 100%;
- monitor Crashlytics/ANRs/auth failure/call failure/message delivery/functions/App Check/Storage/retention;
- rollback/pause criteria predefined;
- record release version, Git SHA, AAB checksum and rollout evidence.

## Stabilization rule between batches

If a defect is found after a batch is accepted:

- open a narrowly scoped stabilization branch from the current official base;
- do not mix the fix with the next feature;
- repeat applicable CI/physical/deployment gates;
- promote a new immutable accepted tag only after owner acceptance.

## Versioning rule

- `pubspec.yaml` remains the only app-version source;
- every distributed/Play upload uses a strictly higher versionCode;
- About screen reads runtime package information;
- a batch may contain multiple candidate builds, but only the owner-accepted artifact is promoted.

## Recovery rule

At every accepted checkpoint, the project must have:

- exact accepted Git SHA;
- immutable acceptance tag;
- `stable/official-recoverable-base` at the accepted state;
- signed debug APK hash;
- signed release/AAB hash when applicable;
- CI run IDs/artifact IDs/digests;
- production audit result;
- physical acceptance record;
- offline Git bundle + SHA-256;
- canonical `F:\NearMeU` synchronized.

The next batch cannot start until this recovery package exists.

## Roadmap flexibility

This order is the default safest sequence. The owner may change priorities later, but a reordered batch must still satisfy dependencies and all operating gates. Historical experimental code is never revived directly; implementation is recreated/reviewed from the current official base.
