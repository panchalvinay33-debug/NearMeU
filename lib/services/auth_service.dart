import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification_service.dart';
import 'presence_coordinator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    return _auth.signInWithCredential(
      await _credentialFor(googleUser),
    );
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'reauthentication-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    await user.reauthenticateWithCredential(
      await _credentialFor(googleUser),
    );
    await user.getIdToken(true);
  }

  Future<void> signOut() async {
    await _prepareForSessionEnd();
    await clearLocalSession();
  }

  /// Clears local credentials after a trusted backend has deleted the account.
  Future<void> clearLocalSession() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> logout() => signOut();

  Future<OAuthCredential> _credentialFor(
    GoogleSignInAccount googleUser,
  ) async {
    final GoogleSignInAuthentication authentication =
        await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );
  }

  Future<void> _prepareForSessionEnd() async {
    try {
      await NotificationService.instance.unregisterCurrentDevice();
    } catch (_) {
      // Session termination must continue even when token cleanup is offline.
    }

    try {
      await PresenceCoordinator.instance.markCurrentUserOffline();
    } catch (_) {
      // Presence is best-effort and must not block sign out.
    }
  }
}
