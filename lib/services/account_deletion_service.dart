import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'presence_service.dart';

class AccountDeletionService {
  AccountDeletionService({
    AuthService? authService,
    FirebaseFunctions? functions,
  }) : _authService = authService ?? AuthService(),
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final AuthService _authService;
  final FirebaseFunctions _functions;
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
      // Reauthentication refreshes auth_time; the backend independently
      // verifies that timestamp before any destructive cleanup starts.
      await _authService.reauthenticateCurrentUser();
      await PresenceService.instance.goOfflineBeforeSignOut();
      await _functions.httpsCallable('deleteCurrentAccount').call<void>();
      await _authService.clearLocalSessionAfterServerDeletion();
    } catch (_) {
      await PresenceService.instance.restoreCurrentState();
      rethrow;
    } finally {
      _deletionInProgress = false;
    }
  }
}
