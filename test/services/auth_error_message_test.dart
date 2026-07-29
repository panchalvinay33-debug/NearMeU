import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/services/auth_error_message.dart';

void main() {
  group('authErrorMessage', () {
    test('explains Google developer error without exposing raw exception', () {
      final error = PlatformException(
        code: 'sign_in_failed',
        message: 'com.google.android.gms.common.api.ApiException: 10:',
      );

      final message = authErrorMessage(error);

      expect(message, contains('latest verified version'));
      expect(message, isNot(contains('ApiException')));
    });

    test('maps Firebase network failures', () {
      final error = FirebaseAuthException(code: 'network-request-failed');

      expect(authErrorMessage(error), contains('internet connection'));
    });

    test('uses a safe generic fallback', () {
      expect(
        authErrorMessage(StateError('private implementation detail')),
        'Google sign-in could not be completed. Please try again.',
      );
    });
  });
}
