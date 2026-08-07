# NearMeU Batch08.1 — Physical Device Acceptance Matrix

Status: test template. Coding may complete before these checks; Batch08.1 acceptance may not.

Use `tool/run_connected_android_compatibility.ps1` first on each USB-connected device to record manufacturer/model/API/RAM/install/start evidence. Then perform the functional checks below manually.

## Required representative coverage

Use as many real devices as reasonably available, prioritizing:

- Samsung / One UI
- Xiaomi / Redmi / Poco / HyperOS or MIUI
- Vivo / iQOO / Funtouch OS
- Oppo / Realme / ColorOS / realme UI
- Motorola / near-stock Android
- Pixel / AOSP-like Android
- at least one lower-RAM / lower-end phone

No statement of universal Android compatibility is allowed from this matrix. Untested manufacturers/OS variants remain unverified.

## Per-device record

Record:

- manufacturer / model
- Android version / API
- RAM class
- primary ABI
- clean install PASS/FAIL
- update install PASS/FAIL
- cold start PASS/FAIL
- warm start PASS/FAIL
- sign-in / session recovery PASS/FAIL
- Nearby with location allowed PASS/FAIL
- Nearby with location denied PASS/FAIL
- revoke location after use and recover PASS/FAIL
- Chats list open PASS/FAIL
- chat open PASS/FAIL
- text send/receive PASS/FAIL
- photo media PASS/FAIL or N/A
- video media PASS/FAIL or N/A
- voice media PASS/FAIL or N/A
- notifications allowed PASS/FAIL
- notifications denied graceful behavior PASS/FAIL
- profile sharing HTTPS app link PASS/FAIL
- offline cached Nearby/Chats PASS/FAIL
- reconnect refresh PASS/FAIL
- background/resume PASS/FAIL
- force-stop/reopen recovery PASS/FAIL
- battery optimization/background restriction notes
- any OEM-specific permission dialog behavior

## Manufacturer-specific observations

### Samsung

Check sleeping/deep-sleep app behavior, notification delivery after backgrounding, and location permission changes.

### Xiaomi / Redmi / Poco

Check autostart/background restrictions, battery saver impact, notification permission behavior, and app relaunch after aggressive process cleanup.

### Vivo / iQOO

Check background power management, notification delivery, location permission state changes, and process restart behavior.

### Oppo / Realme

Check battery/background restrictions, startup management where exposed, notifications, and reconnect behavior after background cleanup.

### Motorola / Pixel / near-stock Android

Use as a baseline for standard Android permission, notification, background and lifecycle behavior.

## Low-end acceptance

At least one lower-RAM/lower-end real phone should verify:

- startup remains responsive
- Nearby and Chats cache-first screens remain usable
- opening a chat does not immediately crash under memory pressure
- media selection does not permanently stall the UI
- background/reopen restores a usable state

## Acceptance rule

Batch08.1 can be accepted only when automated compatibility CI is green, the built APK compatibility report is clean, representative physical evidence is recorded, no major OEM-specific blocker remains unresolved, and the owner explicitly accepts the result.

Batch09 remains blocked until then.
