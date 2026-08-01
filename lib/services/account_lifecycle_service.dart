import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'presence_service.dart';

class AccountLifecycleState {
  const AccountLifecycleState({required this.isClosed});

  final bool isClosed;
}

class AccountLifecycleService {
  AccountLifecycleService({
    AuthService? authService,
    FirebaseFunctions? functions,
  }) : _authService = authService ?? AuthService(),
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final AuthService _authService;
  final FirebaseFunctions _functions;
  bool _closeInProgress = false;

  Future<AccountLifecycleState> ensureIdentityContinuity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final result = await _functions
        .httpsCallable('ensureIdentityContinuity')
        .call<Map<dynamic, dynamic>>();
    final data = result.data;
    return AccountLifecycleState(isClosed: data['accountState'] == 'closed');
  }

  Future<bool> reactivateCurrentAccount() async {
    final result = await _functions
        .httpsCallable('reactivateCurrentAccount')
        .call<Map<dynamic, dynamic>>();
    return result.data['reactivated'] == true;
  }

  Future<void> closeCurrentAccount() async {
    if (_closeInProgress) {
      throw StateError('Account close is already in progress.');
    }

    if (FirebaseAuth.instance.currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    _closeInProgress = true;
    var serverCloseCompleted = false;
    try {
      await _authService.reauthenticateCurrentUser();
      await PresenceService.instance.goOfflineBeforeSignOut();
      await _functions.httpsCallable('closeCurrentAccount').call<void>();
      serverCloseCompleted = true;
      await _authService.clearLocalSessionAfterServerDeletion();
    } catch (_) {
      if (!serverCloseCompleted) {
        await PresenceService.instance.restoreCurrentState();
      } else {
        await _authService.clearLocalSessionAfterServerDeletion();
      }
      rethrow;
    } finally {
      _closeInProgress = false;
    }
  }
}
