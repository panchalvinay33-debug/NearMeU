#!/usr/bin/env bash
set -euo pipefail

required_files=(
  docs/PRIVACY_POLICY_DRAFT.md
  docs/ACCOUNT_DELETION_PAGE_DRAFT.md
  docs/INTERNAL_TEST_QA_MATRIX.md
  store/PLAY_STORE_LISTING.md
  store/DATA_SAFETY_WORKSHEET.md
)

for file in "${required_files[@]}"; do
  if [[ ! -s "$file" ]]; then
    echo "Missing or empty launch document: $file" >&2
    exit 1
  fi
done

# Drafts must keep unmistakable placeholders until owner-controlled facts exist.
required_placeholders=(
  "[PRIVACY POLICY URL]"
  "[ACCOUNT DELETION URL]"
  "[SUPPORT OR PRIVACY EMAIL]"
  "[LEGAL PERSON OR COMPANY NAME]"
)

for placeholder in "${required_placeholders[@]}"; do
  if ! grep -R -F -q "$placeholder" docs store; then
    echo "Expected publication placeholder is missing: $placeholder" >&2
    exit 1
  fi
done

# The store package must identify the shipping Android package and Firebase project.
grep -F -q 'com.nearmeu.nearmeu' store/DATA_SAFETY_WORKSHEET.md
grep -F -q 'nearmeu-e82c7' store/DATA_SAFETY_WORKSHEET.md

# Claims in the drafts must remain aligned with the implemented privacy controls.
grep -F -q 'android:allowBackup="false"' android/app/src/main/AndroidManifest.xml
grep -F -q 'android:usesCleartextTraffic="false"' android/app/src/main/AndroidManifest.xml
grep -F -q 'firebase_app_check:' pubspec.yaml
grep -F -q 'firebase_crashlytics:' pubspec.yaml
grep -F -q 'firebase_analytics:' pubspec.yaml
grep -F -q 'firebase_performance:' pubspec.yaml

# Never permit credential-like material in publication documents.
if grep -R -E -i \
  '(password[[:space:]]*[:=][[:space:]]*[^[]|AIza[0-9A-Za-z_-]{20,}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' \
  docs/PRIVACY_POLICY_DRAFT.md \
  docs/ACCOUNT_DELETION_PAGE_DRAFT.md \
  docs/INTERNAL_TEST_QA_MATRIX.md \
  store/PLAY_STORE_LISTING.md \
  store/DATA_SAFETY_WORKSHEET.md; then
  echo 'Possible credential or private key found in store launch documents.' >&2
  exit 1
fi

# Listing copy must not make unsafe absolute guarantees.
if grep -R -E -i \
  '(100% secure|perfect security|guaranteed match|completely anonymous|untraceable)' \
  store/PLAY_STORE_LISTING.md docs/PRIVACY_POLICY_DRAFT.md; then
  echo 'Unsafe absolute privacy/security claim found in publication copy.' >&2
  exit 1
fi

echo 'Store launch documentation package validated.'
