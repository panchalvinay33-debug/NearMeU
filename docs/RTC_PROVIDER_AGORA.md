# NearMeU RTC Provider — Agora

Status: configured external service; future runtime use remains locked until the owning batch is explicitly unlocked.

## Provider decision

NearMeU uses Agora RTC as the planned real-time communications provider for:

- Batch09 — one-to-one Audio Calling
- Batch10 — one-to-one Video Calling

An Agora project named `NearMeU` has already been created in the Agora Console and RTC service is available on the account/project.

## Configuration state

- Provider: Agora
- Agora project: NearMeU
- RTC plan observed during setup: Free Plan
- Agora App ID: configured in the Agora project; exact value is intentionally not duplicated in governance documentation
- Agora App Certificate: configured; treated as a secret
- Signaling availability may be used only if a future accepted design explicitly requires it

## Secret handling rule

The Agora App Certificate, token signing secret, REST credentials, customer secret, temporary tokens, or any equivalent privileged credential must never be committed to GitHub, Flutter source, Android resources, screenshots stored as project evidence, or client-distributed configuration.

The client may use the Agora App ID where required by the Agora SDK, but privileged token generation must be server-side. Production calling must use short-lived server-issued RTC tokens; the App Certificate must remain only in approved secret storage / backend runtime configuration.

If a certificate or privileged credential is ever exposed publicly or committed to source control, rotate it before production use.

## Batch09 / Batch10 architecture boundary

Agora transports real-time audio/video media. NearMeU remains responsible for the product call lifecycle and authorization contract, including authenticated caller/callee identity, block enforcement, suspension/deletion checks, call invitation/state, timeout/missed-call behavior, call history, abuse controls, and recovery.

Historical Batch09 calling branches are reference-only. They are not accepted source and must not be deployed or merged directly. New Audio/Video Calling work must start fresh from the then-current accepted NearMeU base and follow the permanent deployment gate and production-audit rules.

## Production activation gate

Agora being configured does not mean Batch09 or Batch10 is accepted or deployed. Production use is allowed only after the owning batch has:

1. been explicitly unlocked by the owner;
2. been implemented on a fresh accepted-base branch;
3. passed CI and security checks;
4. passed focused two-device physical tests;
5. received owner acceptance;
6. merged to exact `main`;
7. passed NearMeU deployment gate before backend production changes;
8. passed production audit after deployment.

This document records provider/setup truth only; it does not upgrade Audio Calling or Video Calling to PASS.