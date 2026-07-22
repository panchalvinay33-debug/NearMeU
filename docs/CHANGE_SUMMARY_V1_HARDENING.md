# Initial V1 hardening change summary

## Root causes addressed

- The onboarding UI stored `Men` and `Women`, while validation and Firestore accepted only `Male` and `Female`.
- Missing legacy ages were parsed as the minimum adult age, allowing incomplete profiles to look verified.
- Nearby eligibility did not require both users' preferences to match.
- Android release builds used the public debug signing key.
- The repository had no automated Flutter or Firestore-rule quality gate.

## User impact

- New users can complete onboarding without a preference-value permission failure.
- Profiles with unknown ages remain incomplete and do not appear as verified adults.
- Nearby results better reflect the product's mutual matching promise.
- Production bundles cannot silently use debug signing.
- Pull requests now receive repeatable formatting, analysis, test, build, and rules checks.
