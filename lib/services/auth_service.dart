import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'presence_service.dart';

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

  Future<void> signOut() => logout();

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
      await user.delete();
    }
  }

  Future<void> deleteAccount() async {
    await deleteFirebaseAuthAccount();
  }

  Future<void> logout() async {
    await PresenceService.instance.goOfflineBeforeSignOut();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
