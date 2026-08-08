# NearMeU V1 Auth Startup Validation

Purpose: trigger the existing pull-request quality gate against the locked V1 testing baseline without changing runtime behavior.

Runtime under test:
- Base branch: `v1/testing-baseline`
- Expected cold-start flow: Login screen -> Continue with Google -> account selection/verification -> existing complete profile to Nearby; missing/incomplete profile to Get Started.
- No feature additions in this validation branch.
