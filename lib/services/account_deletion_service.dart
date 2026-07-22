import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import 'presence_service.dart';
import 'user_service.dart';

class AccountDeletionService {
  AccountDeletionService({
    AuthService? authService,
    ChatService? chatService,
    UserService? userService,
  }) : _authService = authService ?? AuthService(),
       _chatService = chatService ?? ChatService(),
       _userService = userService ?? UserService();

  final AuthService _authService;
  final ChatService _chatService;
  final UserService _userService;
  bool _deletionInProgress = false;

  Future<void> deleteCurrentAccount() async {
    if (_deletionInProgress) {
      throw StateError('Account deletion is already in progress.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    _deletionInProgress = true;
    try {
      // Verify the sensitive operation before removing any account data.
      await _authService.reauthenticateCurrentUser();
      await NotificationService.instance.unregisterCurrentDevice();
      await PresenceService.instance.goOfflineBeforeSignOut();
      await _chatService.deleteCurrentUserChats(uid);
      await _userService.deleteCurrentUserData(uid);
      await _authService.deleteFirebaseAuthAccount();
    } finally {
      _deletionInProgress = false;
    }
  }
}
