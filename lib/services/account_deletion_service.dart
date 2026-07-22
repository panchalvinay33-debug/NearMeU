import 'package:cloud_functions/cloud_functions.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message, {this.requiresRecentLogin = false});

  final String message;
  final bool requiresRecentLogin;

  @override
  String toString() => message;
}

class AccountDeletionService {
  AccountDeletionService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<void> deleteCurrentAccount() async {
    try {
      final result = await _functions
          .httpsCallable('deleteMyAccount')
          .call<Map<String, dynamic>>();
      if (result.data['success'] != true) {
        throw const AccountDeletionException(
          'Account deletion did not complete. Please try again.',
        );
      }
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      final recentLoginRequired =
          error.code == 'failed-precondition' &&
              details is Map &&
              details['reason'] == 'RECENT_LOGIN_REQUIRED';
      throw AccountDeletionException(
        recentLoginRequired
            ? 'Please sign in again before deleting your account.'
            : (error.message ??
                'Could not delete your account. Please try again.'),
        requiresRecentLogin: recentLoginRequired,
      );
    }
  }
}
