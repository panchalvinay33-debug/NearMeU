# Batch 04 Physical Test — Clear Chat and deletion semantics

Target version: `1.0.7+8`

Package: `com.nearmeu.nearmeu`

Accepted starting base: Batch 03 final documented/recovery commit `f487be76f958c06966e15f3db9cbbec65f5cfa9c`.

## Accepted artifact

- Branch head tested before acceptance docs: `f22b36690b7ca65828ce2db809a89abe9931f83e`
- Build workflow: `30695802197` / #27 — PASS
- Quality workflow: `30695802185` / #422 — PASS
- Artifact ID: `8817336599`
- Artifact digest: `sha256:6a012c299547e7b32f9f76e5c1ece24e2b4110111bae40289372b1624ccbb39a`
- APK SHA-256: `24e770e3b09cfcb2608b8a8283405cef282f62a4832a3e67fd3a625a2bd2deb8`
- Signing certificate SHA-256: `B6:22:4C:99:2D:67:AC:6A:99:E9:43:56:4E:B8:23:C6:9F:B7:65:C7:12:72:53:41:C1:07:5F:AB:D1:47:29:1B`
- Firebase project: `nearmeu-e82c7`
- Region: `asia-south1`

## Production deployment

Owner deployed `clearPrivateChat` on 2026-08-01 from the canonical workspace `F:\NearMeU`.

Firebase CLI evidence supplied by the owner showed:

```text
functions[clearPrivateChat(asia-south1)] Successful create operation.
Deploy complete!
```

An initial Clear Chat attempt before this production deployment returned `NOT_FOUND`. This was expected because the new callable had not yet been created in production. The same installed APK was retested after deployment and Clear Chat passed; no APK reinstall or runtime code change was required.

## Physical acceptance result

Owner supplied two-account/device screenshots and then explicitly confirmed on 2026-08-01: `Yes sab thik he check ho gaya`.

Accepted focused results:

1. **Direct-update safety — PASS**
   - Batch 04 was installed as an update without uninstall/data wipe.
   - Existing accepted app state remained usable.

2. **Clear Chat — actor only — PASS after production deploy**
   - `Clear Chat` is present in the chat three-dot menu with a permanent-for-you warning.
   - After `clearPrivateChat` production deployment, the clear action completed successfully.
   - The other participant's copy remained independent.

3. **No resurrection / post-clear continuation — PASS**
   - Owner confirmed the focused Clear Chat test was complete and working after deployment.
   - Cleared history did not need a new APK build to remain hidden because the server callable was the missing production dependency.

4. **Delete for me — PASS**
   - Owner screenshots showed the selected message removed only from the actor side while the other participant retained it.

5. **Delete for everyone — PASS**
   - Owner screenshots showed `This message was unsent` on both sides for the sender action.

6. **Focused tick regression — PASS**
   - Screenshots showed normal sent/delivered/read tick progression remained functional.

7. **Representative chat regression — PASS**
   - Owner explicitly reported the remaining focused checks were all working.

## Acceptance gate

Batch 04 physical acceptance is **PASSED**.

- CI and permanently signed build: PASS
- package/signing/versionCode direct-update compatibility: PASS
- production `clearPrivateChat` deployment: PASS
- focused physical matrix: PASS
- owner acceptance: PASS on 2026-08-01

Do not ask the owner to repeat this Batch 04 matrix unless a later verified regression specifically requires it.
