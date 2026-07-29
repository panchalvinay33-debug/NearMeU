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

python3 - <<'PY'
import json
import re
from pathlib import Path

path = Path("android/app/google-services.json")
try:
    config = json.loads(path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    raise SystemExit(f"Release configuration error: invalid google-services.json: {error}")

clients = config.get("client") or []
matching = [
    client
    for client in clients
    if client.get("client_info", {})
    .get("android_client_info", {})
    .get("package_name")
    == "com.nearmeu.nearmeu"
]
if len(matching) != 1:
    raise SystemExit(
        "Release configuration error: google-services.json must contain exactly "
        "one NearMeU Android client."
    )

oauth_clients = matching[0].get("oauth_client") or []
android_clients = [client for client in oauth_clients if client.get("client_type") == 1]
web_clients = [client for client in oauth_clients if client.get("client_type") == 3]

if not android_clients:
    raise SystemExit(
        "Release configuration error: Google Sign-In Android OAuth client is missing."
    )
if not web_clients:
    raise SystemExit(
        "Release configuration error: Google Sign-In web OAuth client is missing."
    )

sha1_pattern = re.compile(r"^[0-9a-fA-F]{40}$")
for client in android_clients:
    android_info = client.get("android_info") or {}
    if android_info.get("package_name") != "com.nearmeu.nearmeu":
        raise SystemExit(
            "Release configuration error: Android OAuth package does not match NearMeU."
        )
    certificate_hash = str(android_info.get("certificate_hash") or "")
    if not sha1_pattern.fullmatch(certificate_hash):
        raise SystemExit(
            "Release configuration error: Android OAuth certificate hash must be a "
            "40-character SHA-1 value."
        )

for client in android_clients + web_clients:
    client_id = str(client.get("client_id") or "")
    if not client_id.endswith(".apps.googleusercontent.com"):
        raise SystemExit(
            "Release configuration error: malformed Google OAuth client ID."
        )
PY

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
