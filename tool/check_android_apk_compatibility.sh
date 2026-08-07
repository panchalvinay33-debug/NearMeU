#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-debug.apk}"

if [[ ! -f "$APK_PATH" ]]; then
  echo "Compatibility check failed: APK not found at $APK_PATH" >&2
  exit 1
fi

if [[ -z "${ANDROID_SDK_ROOT:-}" ]]; then
  echo "Compatibility check failed: ANDROID_SDK_ROOT is not set." >&2
  exit 1
fi

AAPT="$(find "$ANDROID_SDK_ROOT/build-tools" -type f -name aapt 2>/dev/null | sort -V | tail -n 1)"
if [[ -z "$AAPT" || ! -x "$AAPT" ]]; then
  echo "Compatibility check failed: Android aapt tool not found." >&2
  exit 1
fi

BADGING="$($AAPT dump badging "$APK_PATH")"
printf '%s\n' "$BADGING"

required_value() {
  local label="$1"
  local pattern="$2"
  local value
  value="$(grep -m1 -oE "$pattern" <<< "$BADGING" | sed -E "s/^[^']*'([^']+)'.*/\1/" || true)"
  if [[ -z "$value" ]]; then
    echo "Compatibility check failed: unable to resolve $label from APK." >&2
    exit 1
  fi
  printf '%s' "$value"
}

PACKAGE_ID="$(required_value package "package: name='[^']+'")"
MIN_SDK="$(required_value minSdk "sdkVersion:'[^']+'")"
TARGET_SDK="$(required_value targetSdk "targetSdkVersion:'[^']+'")"

if [[ "$PACKAGE_ID" != "com.nearmeu.nearmeu" ]]; then
  echo "Compatibility check failed: unexpected package id $PACKAGE_ID" >&2
  exit 1
fi

if ! [[ "$MIN_SDK" =~ ^[0-9]+$ && "$TARGET_SDK" =~ ^[0-9]+$ ]]; then
  echo "Compatibility check failed: non-numeric SDK values min=$MIN_SDK target=$TARGET_SDK" >&2
  exit 1
fi

if (( TARGET_SDK < 35 )); then
  echo "Compatibility check failed: targetSdk $TARGET_SDK is below the Batch08.1 policy floor 35." >&2
  exit 1
fi

NATIVE_LINE="$(grep -m1 '^native-code:' <<< "$BADGING" || true)"
if [[ -n "$NATIVE_LINE" && "$NATIVE_LINE" != *"arm64-v8a"* ]]; then
  echo "Compatibility check failed: native APK payload does not include arm64-v8a." >&2
  exit 1
fi

sensitive_features=(
  android.hardware.camera
  android.hardware.microphone
  android.hardware.location
  android.hardware.location.gps
  android.hardware.location.network
  android.hardware.telephony
  android.hardware.bluetooth
)

for feature in "${sensitive_features[@]}"; do
  if grep -Eq "^uses-feature:.*${feature}" <<< "$BADGING"; then
    echo "Compatibility check failed: $feature is marked as required and may filter Play Store installs." >&2
    exit 1
  fi
done

cat <<SUMMARY

NearMeU ANDROID COMPATIBILITY INSPECTION PASS
Package        : $PACKAGE_ID
Minimum SDK    : $MIN_SDK
Target SDK     : $TARGET_SDK
Native ABIs    : ${NATIVE_LINE:-none declared in badging output}
APK            : $APK_PATH
SUMMARY
