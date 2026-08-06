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
| Freeze post-Base08 work and restore Base08 boundary | PR #112 | Owner chose to stop future work and re-certify Base08 after experimental work made state/recovery harder to reason about. | Merged as `b6837ce2dd90bdc4db87a153089fcaf1cf74a441` after cleanup + narrow stabilization. |
| Firestore `messages.timestamp` automatic collection index restored | production index correction + accepted source cleanup | Chats failed with failed-precondition because a later override replaced automatic collection index behavior. | Fresh Chats physical PASS. |
| Delivery receipt backend limit aligned to client backlog cap | stabilization commit within PR #112 | Client could submit 200 IDs while backend accepted 100, blocking delivered acknowledgements. | Fresh two-phone grey delivered tick PASS. |
| Presence stale-state self-heal | stabilization commit within PR #112 | Chat last-seen writes could set offline while PresenceService cached old true state. | Fresh two-phone mutual Online PASS. |
| Accurate About version display | PR #114 | About hardcoded `Version 1.0.0` instead of real package version `1.0.11+12`. | CI/recoverable build PASS; focused owner physical About check pending at time of this ledger update. |
| Recovery/deployment governance hardening | governance branch/PR created after owner instruction | Prevent future rollback from requiring forensic reconstruction. Adds one-command recovery, machine manifest, deployment gate, production drift audit and consolidated blueprint. | Governance-only; must pass CI/merge before becoming official process. |

## Post-Base08 experiments — historical only

These are not accepted product scope:

- Admin A01–A08 work;
- PR #103 Batch09 Agora audio calling;
- PR #108 Batch09 call-history patch;
- PR #111 Batch09 R2 audio calling;
- Batch09 checkpoints and related experimental branches.

On 2026-08-06 the owner explicitly required NearMeU to remain only at Base08. Where branch deletion tooling was unavailable, post-Base08 branch tips were neutralized to the Base08-clean main state. Closed/superseded PRs remain GitHub historical records only.

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
