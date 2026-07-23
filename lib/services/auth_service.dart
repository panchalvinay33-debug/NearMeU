import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification_service.dart';
import 'presence_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    await _googleSignIn.signOut();

    final credential = await _requestGoogleCredential();
    if (credential == null) return null;
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => logout();

  Future<void> reauthenticateCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final credential = await _requestGoogleCredential();
    if (credential == null) {
      throw FirebaseAuthException(
        code: 'reauthentication-cancelled',
        message: 'Account verification was cancelled.',
      );
    }

    await user.reauthenticateWithCredential(credential);
  }

  /// Deletes only the Firebase Authentication account.
  /// Firestore/chat cleanup must be performed before calling this method.
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
      await reauthenticateCurrentUser();
      await user.delete();
    }
  }

  Future<void> deleteAccount() async {
    await deleteFirebaseAuthAccount();
  }

  Future<void> logout() async {
    await NotificationService.instance.unregisterCurrentDevice();
    await PresenceService.instance.goOfflineBeforeSignOut();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<OAuthCredential?> _requestGoogleCredential() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }
}
