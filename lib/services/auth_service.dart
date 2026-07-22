import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'presence_coordinator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      await PresenceCoordinator.instance.markCurrentUserOnline();
      return result;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await PresenceCoordinator.instance.markCurrentUserOffline();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Deletes only the Firebase Authentication account.
  /// Firestore/chat cleanup will be performed before calling this method.
  Future<void> deleteFirebaseAuthAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    try {
      await PresenceCoordinator.instance.markCurrentUserOffline();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        rethrow;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) rethrow;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      await PresenceCoordinator.instance.markCurrentUserOffline();
      await user.delete();
    }
  }

  Future<void> deleteAccount() async {
    await deleteFirebaseAuthAccount();
  }

  Future<void> logout() async {
    await PresenceCoordinator.instance.markCurrentUserOffline();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
