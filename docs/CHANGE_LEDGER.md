# NearMeU Change Ledger

Last updated: 2026-08-06

Purpose: keep a human-readable record of important accepted changes and corrective transitions: what changed, why it changed, where it merged, and whether it is accepted runtime, documentation-only evidence, or rejected/superseded history.

This ledger does not replace `config/official_base_manifest.json`; the manifest remains the exact current recovery truth.

## Accepted controlled batches

| Period | Batch | Runtime PR / evidence | What and why | Status |
|---|---|---|---|---|
| 2026-08 | 00 | PR #84 | Froze governance, roadmap, product decisions and controlled batch/test registers so future runtime work had explicit gates. | ACCEPTED governance |
| 2026-08-01 | 01 | PR #86; docs promotion PR #87 | Separated sent, delivered and read truth; owner physically verified grey delivered and blue read ticks. | ACCEPTED |
| 2026-08-01 | 02 | PR #88; docs promotion PR #89 | Hardened private photo/video/voice-message reliability, pending outbox and download recovery. | ACCEPTED |
| 2026-08-01 | 03 | PR #90; docs promotion PR #91 | Established encrypted local-first history plus seven-day temporary delivery cloud and production retention functions. | ACCEPTED |
| 2026-08-01 | 04 | PR #92; docs promotion PR #93 | Defined trusted Clear Chat, Delete for Me and Delete for Everyone/Unsend semantics with physical acceptance. | ACCEPTED |
| 2026-08-01 | 05 | PR #94; docs promotion PR #95 | Added verified identity continuity, reversible Close Account and same-account reactivation while preserving eligible history. | ACCEPTED |
| 2026-08-01 | 06 | PR #96; docs promotion PR #97 | Added private trusted Premium entitlement truth and Free outbound media/voice gating. | ACCEPTED |
| 2026-08-02 | 07 | PR #98; docs promotion PR #99 | Added six-month Premium recovery architecture and separate recovery store/media namespace. Receiver-media pre/post-download physical proof remained explicitly deferred. | ACCEPTED with deferred evidence |
| 2026-08-02 | 08 | PR #100; docs closeout PR #101 | Added explicit profile sharing, opaque revocable public IDs, trusted resolution, block protection and HTTPS deep-link recovery. | ACCEPTED |

## Base08 re-certification / cleanup — 2026-08-06

| Change | Reference | Why | Result |
|---|---|---|---|
| Freeze post-Base08 work and restore Base08 boundary | PR #112 | Owner chose to stop future work and re-certify Base08 after experimental work made state/recovery harder to reason about. | Merged cleanup/re-certification base. |
| Accurate About version display | PR #114 | About hardcoded `Version 1.0.0` instead of real package version `1.0.11+12`. | Merged; automated gates and owner physical About check PASS. |
| Presence consistency across Nearby, Chats and Chat | PR #116 | Chat read/dispose paths could disagree with lifecycle-owned presence and stale online state. | Merged as `92341b4a9641ea1174186724d970feb4ffa12fdb`; Quality #621 PASS, Recoverable #173 PASS, artifact `8964462769`; owner physically verified Nearby/Chats/Chat presence agreement, background ageing and read-without-offline behavior PASS. |
| Cache-first Nearby and Chats / low-connectivity hardening | PR #117 | Network-first startup produced a web-page-like wait and weak-network blank/loading behavior despite an existing local cache. | Physically tested runtime `87f5b05461f0e211c1f710dabba27255436ef7cd`; merged as `f01c8ea9bbd43728f839ee24b5f7280d9ba2d4c7`; Quality #623 PASS, Recoverable #174 PASS, artifact `8965916278`; owner reported Normal / Offline / Reconnect all PASS. |
| Recovery/deployment governance hardening R2 | PR #118 | Make the final Base08 state self-documenting and one-command recoverable without changing the physically tested consumer runtime. | Governance-only closeout candidate. Promotion script blocks non-governance drift after tested runtime and atomically promotes immutable tag + recovery branch. Production audit remains pending until run from merged clean main. |

## Persistent evidence gaps that must not be silently upgraded

- Batch07 receiver-media pre-download/post-download Premium recovery: **OWNER-DEFERRED / NOT PHYSICALLY VERIFIED / NOT PASS**.
- Batch08 custom `nearmeu://` fallback: implemented, but **not independently screenshot-verified**. HTTPS warm/cold app links were physically verified.

## Post-Base08 experiments — historical only

These are not accepted product scope:

- Admin A01–A08 experiments in the consumer/shared-backend repository history;
- PR #103 Batch09 Agora audio calling;
- PR #108 Batch09 call-history patch;
- PR #111 Batch09 R2 audio calling;
- Batch09 checkpoints and related experimental branches.

Closed/superseded PRs remain GitHub historical evidence only and do not override the official-base manifest.

## Merge/acceptance recording rule going forward

Every future accepted batch/change must append an entry containing:

- date;
- batch/change name;
- reason;
- source branch;
- tested source/merge-ref SHA;
- runtime PR number;
- merge SHA;
- CI run IDs;
- signed artifact ID/digest and APK/AAB SHA-256;
- production resources changed/deployed;
- physical test decision;
- owner acceptance;
- recovery promotion SHA;
- any deferred evidence.

No future acceptance is complete until this ledger and `config/official_base_manifest.json` agree.
