import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'presence_service.dart';

class AccountDeactivationService {
  AccountDeactivationService({
    AuthService? authService,
    FirebaseFunctions? functions,
  }) : _authService = authService ?? AuthService(),
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final AuthService _authService;
  final FirebaseFunctions _functions;
  bool _deactivationInProgress = false;

  Future<bool> reactivateCurrentAccountIfNeeded() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final result = await _functions
        .httpsCallable('reactivateCurrentAccount')
        .call<Map<dynamic, dynamic>>();
    return result.data['reactivated'] == true;
  }

  Future<void> deactivateCurrentAccount() async {
    if (_deactivationInProgress) {
      throw StateError('Account deactivation is already in progress.');
    }
    if (FirebaseAuth.instance.currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    _deactivationInProgress = true;
    var serverDeactivationCompleted = false;
    try {
      await _authService.reauthenticateCurrentUser();
      await PresenceService.instance.goOfflineBeforeSignOut();
      await _functions.httpsCallable('deactivateCurrentAccount').call<void>();
      serverDeactivationCompleted = true;
      await _authService.clearLocalSessionAfterServerDeletion();
    } catch (_) {
      if (!serverDeactivationCompleted) {
        await PresenceService.instance.restoreCurrentState();
      } else {
        await _authService.clearLocalSessionAfterServerDeletion();
      }
      rethrow;
    } finally {
      _deactivationInProgress = false;
    }
  }
}
