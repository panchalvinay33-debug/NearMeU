# NearMeU V1 manual verification matrix

Run these checks against a staging Firebase project with two real Android devices and two non-admin accounts.

## Onboarding

- Select Men and complete registration; verify Firestore stores `Male`.
- Select Women and complete registration; verify Firestore stores `Female`.
- Verify ages below 18, above 99, blank ages, and non-numeric ages cannot save.
- Verify a legacy profile with no age returns to profile completion and does not appear in Nearby.

## Nearby

- Verify mutually compatible users appear.
- Verify one-sided preference matches do not appear.
- Verify blocked, suspended, underage, and missing-age profiles do not appear.
- Verify distances are rounded to whole kilometres and no exact coordinates are displayed.

## Release build

- Verify a debug build works without `android/key.properties`.
- Verify a release build fails clearly without `android/key.properties`.
- Verify a configured upload key produces a signed Android App Bundle.

## Regression

- Verify Google Sign-In, Nearby, Chats, Support, Settings, blocking, reporting, logout, and account deletion still open and behave normally.
