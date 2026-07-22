# NearMeU realtime stability test plan

Use two different Firebase accounts on two physical Android phones.

## Presence

1. Launch NearMeU on both phones and keep both apps in the foreground.
2. Confirm each account shows the other as Online in Nearby and the chat header.
3. Put one app in the background and refresh/observe the other phone.
4. Confirm the backgrounded account becomes Offline and its last-seen time updates.
5. Resume the backgrounded app and confirm it becomes Online again.
6. Sign out and confirm the account does not remain Online.

## Nearby directory

1. Sign in with an older profile and record the Nearby count with filters cleared.
2. Sign in with a newly created profile and clear all filters.
3. Confirm both accounts receive the same eligible directory pool, excluding only themselves, blocked accounts, suspended accounts and under-18 profiles.
4. Confirm legacy profiles without an email, gender or looking-for value still appear in the default directory when they have a nickname and adult age.
5. Confirm online profiles sort first, then offline profiles, with nearest profiles first inside each group.
6. Confirm the list updates without restarting when another user's presence changes.

## Unread badge

1. Keep the receiver on Nearby.
2. Send three messages from the other phone.
3. Confirm the Chats bottom-tab badge shows 3 without opening Chats.
4. Open the conversation and confirm the badge clears for that conversation.
5. Repeat while the receiver is on Settings.

## Notifications

The Flutter client requests Android notification permission, creates the high-importance channel and registers each signed-in device token under `users/{uid}/devices/{deviceId}`.

Actual background or terminated-app push delivery still requires a trusted backend (for example a Cloud Function triggered by a new chat message). Never place an FCM server key or service-account credential in the Flutter application.
