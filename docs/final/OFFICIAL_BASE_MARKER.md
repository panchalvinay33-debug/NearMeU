# NearMeU — Official Base Marker

Last updated: 2026-07-30 (IST)

## Current source-of-truth

- Default development branch: `main`
- Official recovery branch: `stable/official-base-v1-2026-07-30`
- Official base merge commit: `a743ffa407c145b3852c547d31f33458e8e839b4`
- Android package: `com.nearmeu.nearmeu`

## Required GitHub protection

`main` is protected by an active ruleset requiring:

- pull requests before merging
- `Flutter checks`
- `Firebase rules tests`
- `Cloud Functions checks`
- deletion restriction
- force-push blocking

## Recovery rule

All future work starts from current `main` on a focused branch. If a change breaks the app, create a recovery branch from `stable/official-base-v1-2026-07-30`, validate it, and return it to `main` through a green pull request. Never force-push or directly rewrite `main`.

## External state not stored in Git

GitHub does not contain secret values, the permanent keystore file, Firebase Console settings, App Check debug tokens, Play Console state, or live production data. Those must remain in GitHub Actions secrets, secure owner backups, Firebase/Google consoles, and documented operational records.