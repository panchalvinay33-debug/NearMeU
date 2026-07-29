import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Converts authentication failures into short, safe messages for users.
///
/// Raw exception text may contain implementation details and should be sent to
/// observability tooling instead of being displayed in the UI.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'account-exists-with-different-credential' =>
        'This email is already linked to another sign-in method.',
      'network-request-failed' =>
        'No internet connection. Check your network and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a little and try again.',
      'user-disabled' =>
        'This account has been disabled. Please contact support.',
      _ => 'Google sign-in could not be completed. Please try again.',
    };
  }

  if (error is PlatformException) {
    final details =
        '${error.code} ${error.message ?? ''} ${error.details ?? ''}';
    final isDeveloperConfigurationError =
        details.contains('ApiException: 10') ||
        details.contains('DEVELOPER_ERROR');
    if (error.code == 'sign_in_failed' && isDeveloperConfigurationError) {
      return 'Google sign-in is temporarily unavailable for this app build. '
          'Please install the latest verified version.';
    }
    if (error.code == 'network_error') {
      return 'No internet connection. Check your network and try again.';
    }
  }

  return 'Google sign-in could not be completed. Please try again.';
}
