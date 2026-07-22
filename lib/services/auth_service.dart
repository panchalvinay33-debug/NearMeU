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

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _prepareForSessionEnd();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Deletes only the Firebase Authentication account.
  /// Firestore/chat cleanup is currently performed by the caller.
  Future<void> deleteFirebaseAuthAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    try {
      await _prepareForSessionEnd();
      await user.delete();
    } on FirebaseAuthException catch (error) {
      if (error.code != 'requires-recent-login') rethrow;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) rethrow;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      await _prepareForSessionEnd();
      await user.delete();
    }
  }

  Future<void> deleteAccount() async {
    await deleteFirebaseAuthAccount();
  }

  Future<void> logout() async {
    await signOut();
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
