# NearMeU stability verification

Run locally before merging:

```powershell
dart format .
flutter analyze
flutter test
flutter clean
flutter pub get
flutter run
```

Manual checks on two devices:

- send a chat message and verify the conversation badge and bottom Chats badge
- verify the Nearby bottom navigation shows the unread badge before opening Chats
- open the chat and confirm the unread count clears only for that conversation
- send an `https://` link and tap it to open the supporting app or browser
- send a support announcement containing an `https://` link and tap it
- verify unread support announcements sort above read announcements
- tap **Mark all read** and confirm all support cards immediately show **Read**
- verify Nearby, Chats, Support and Settings layouts have not regressed
