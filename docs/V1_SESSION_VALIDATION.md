# NearMeU V1 session persistence validation

Validation-only marker for GitHub Actions.

Target runtime commit: `a88e65508c23f6c4d5c378d0226efaeb18441689`

Expected startup behavior:
- existing Firebase session + complete profile -> app shell
- existing Firebase session + incomplete profile -> onboarding
- no Firebase session -> login screen / Google account chooser
