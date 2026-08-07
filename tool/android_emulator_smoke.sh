#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
PACKAGE_ID="com.nearmeu.nearmeu"
ACTIVITY="com.nearmeu.nearmeu/.MainActivity"

if [[ ! -f "$APK_PATH" ]]; then
  echo "Smoke test failed: APK not found at $APK_PATH" >&2
  exit 1
fi

adb wait-for-device
adb shell input keyevent 82 >/dev/null 2>&1 || true
adb install -r -t "$APK_PATH"
adb shell pm clear "$PACKAGE_ID" >/dev/null 2>&1 || true
adb logcat -c || true

set +e
adb shell am start -W -n "$ACTIVITY" > launch-result.txt 2>&1
launch_status=$?
set -e
cat launch-result.txt
if (( launch_status != 0 )); then
  echo "Smoke test failed: Android could not launch NearMeU." >&2
  exit 1
fi

sleep 12
adb shell dumpsys activity activities > activity-dump.txt || true
adb shell ps -A > process-list.txt 2>/dev/null || adb shell ps > process-list.txt || true
adb logcat -d -v brief > logcat.txt || true

if ! grep -q "$PACKAGE_ID" process-list.txt; then
  echo "Smoke test failed: NearMeU process is not alive after launch." >&2
  tail -n 120 logcat.txt || true
  exit 1
fi

if grep -E "FATAL EXCEPTION|Process: ${PACKAGE_ID}.*(has died|crash)|ANR in ${PACKAGE_ID}" logcat.txt >/dev/null; then
  echo "Smoke test failed: fatal crash/ANR signature detected." >&2
  grep -E -A20 -B5 "FATAL EXCEPTION|ANR in ${PACKAGE_ID}|Process: ${PACKAGE_ID}" logcat.txt | tail -n 160 || true
  exit 1
fi

sdk="$(adb shell getprop ro.build.version.sdk | tr -d '\r')"
release="$(adb shell getprop ro.build.version.release | tr -d '\r')"
abi="$(adb shell getprop ro.product.cpu.abi | tr -d '\r')"
mem_kb="$(adb shell grep MemTotal /proc/meminfo | awk '{print $2}' | tr -d '\r')"

cat <<SUMMARY
NearMeU ANDROID EMULATOR SMOKE PASS
Android API   : $sdk
Android       : $release
ABI           : $abi
Memory kB     : ${mem_kb:-unknown}
Package       : $PACKAGE_ID
APK           : $APK_PATH
SUMMARY
