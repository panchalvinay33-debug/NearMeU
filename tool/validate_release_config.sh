#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "Release configuration error: $*" >&2
  exit 1
}

version=$(awk '/^version:/{print $2; exit}' pubspec.yaml)
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[1-9][0-9]*$ ]] \
  || fail "pubspec.yaml version must look like 1.2.3+45."

grep -Fq 'applicationId = "com.nearmeu.nearmeu"' android/app/build.gradle.kts \
  || fail "Android applicationId changed unexpectedly."
grep -Fq 'versionCode = flutter.versionCode' android/app/build.gradle.kts \
  || fail "Android versionCode must come from pubspec.yaml."
grep -Fq 'versionName = flutter.versionName' android/app/build.gradle.kts \
  || fail "Android versionName must come from pubspec.yaml."
grep -Fq '"package_name": "com.nearmeu.nearmeu"' android/app/google-services.json \
  || fail "Firebase Android package does not match the applicationId."

grep -Fq 'android:allowBackup="false"' android/app/src/main/AndroidManifest.xml \
  || fail "Android backups must be explicitly disabled."
grep -Fq 'android:usesCleartextTraffic="false"' android/app/src/main/AndroidManifest.xml \
  || fail "Cleartext network traffic must remain disabled."
grep -Fq 'android:dataExtractionRules="@xml/data_extraction_rules"' android/app/src/main/AndroidManifest.xml \
  || fail "Android 12+ data extraction rules are missing."
grep -Fq 'android:fullBackupContent="@xml/backup_rules"' android/app/src/main/AndroidManifest.xml \
  || fail "Legacy Android backup rules are missing."

test -s android/app/src/main/res/xml/backup_rules.xml \
  || fail "Legacy backup exclusion rules are missing."
test -s android/app/src/main/res/xml/data_extraction_rules.xml \
  || fail "Android 12+ backup exclusion rules are missing."

grep -Fq 'environment: production-release' .github/workflows/release-aab.yml \
  || fail "Signed AAB workflow must use the protected production environment."
grep -Fq "if: github.ref == 'refs/heads/main'" .github/workflows/release-aab.yml \
  || fail "Signed AAB workflow must be restricted to main."
grep -Fq 'ANDROID_UPLOAD_KEYSTORE_BASE64' .github/workflows/release-aab.yml \
  || fail "Signed AAB workflow is missing private keystore secret wiring."
grep -Fq -- '--obfuscate' .github/workflows/release-aab.yml \
  || fail "Production AAB must preserve the obfuscated release contract."
grep -Fq -- '--split-debug-info=build/symbols' .github/workflows/release-aab.yml \
  || fail "Production AAB must generate Dart symbols."
grep -Fq 'jarsigner -verify -certs' .github/workflows/release-aab.yml \
  || fail "Production AAB signature verification is missing."

tracked_signing_files=$(git ls-files | grep -E '(^|/)(key\.properties|[^/]+\.(jks|keystore))$' || true)
[[ -z "$tracked_signing_files" ]] \
  || fail "Private signing material is tracked: $tracked_signing_files"

echo "Production release configuration is valid for $version."
