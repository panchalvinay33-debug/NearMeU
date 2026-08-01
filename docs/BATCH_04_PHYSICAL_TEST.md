# Batch 04 Physical Test — Clear Chat and deletion semantics

Target version: `1.0.7+8`

Package: `com.nearmeu.nearmeu`

Accepted starting base: Batch 03 final documented/recovery commit `f487be76f958c06966e15f3db9cbbec65f5cfa9c`.

## Install rule

Use the permanently signed Batch 04 APK as an Android update only. Never uninstall or clear app data.

```powershell
.\adb.exe install -r .\NearMeU-Batch-04-v1.0.7-8-Signed.apk
```

## One coordinated acceptance pass

Do this matrix once after CI, signed APK and production `clearPrivateChat` deployment are green.

1. **Direct-update safety**
   - Install over the accepted `1.0.6+7` app.
   - Existing login, chat history, downloaded media and app state remain intact before any destructive test action.

2. **Clear Chat — actor only**
   - Open one expendable two-user chat on device/account A.
   - Confirm `Clear Chat` is present in the top-right three-dot menu.
   - Confirm the destructive warning explicitly says the action is permanent for the current user and the other participant keeps their copy.
   - Clear the chat.
   - The chat disappears from A's chat list.
   - B still sees the pre-clear conversation.

3. **No resurrection**
   - Restart A and reopen the app.
   - The cleared history must not return.
   - If the same A account is available on another device, let that device reconnect/open the chat; content at or before the clear cutoff must disappear there too.

4. **Post-clear continuation**
   - Send a new message after the clear action.
   - The chat may reappear for A, but only post-clear content is visible. Pre-clear content must stay gone.

5. **Local media purge**
   - In the cleared range include at least one previously downloaded photo/video/voice item when practical.
   - After clear, those items must not reopen or reappear from NearMeU local history.

6. **Delete for me**
   - Delete one expendable message for A.
   - It disappears for A and remains visible for B.
   - Restart/reopen A; the deleted item must not immediately reappear from local history.

7. **Delete for everyone**
   - From the sender account, use `Delete for everyone` on a message inside the existing 60-minute window.
   - Both sides show the existing unsent/deleted tombstone behavior.
   - For a media message, its removed media must not remain available through the message.

8. **Focused regressions only**
   - Send one text and confirm single/grey-double/blue-double tick behavior still works.
   - Send/open one representative private-media item and confirm normal media flow still works.
   - Confirm no duplicate messages appear.

## Acceptance gate

Batch 04 is accepted only when:

- CI and permanently signed build pass;
- package/signing/versionCode direct-update compatibility passes;
- production `clearPrivateChat` deployment succeeds;
- the focused matrix above passes;
- owner explicitly accepts the build.

Do not repeat earlier Batch 01–03 full matrices unless a verified regression appears.
