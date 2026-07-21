import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class SuspensionException implements Exception {
  const SuspensionException();

  @override
  String toString() => 'Account suspended';
}

class SuspensionService {
  SuspensionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuthService _authService;

  Stream<AppUser?> streamCurrentUser() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<AppUser?>.value(null);
      }

      return _firestore.collection('users').doc(user.uid).snapshots().map(
        (doc) {
          if (!doc.exists || doc.data() == null) return null;
          return AppUser.fromMap(doc.data()!, doc.id);
        },
      );
    });
  }

  Future<bool> isSuspended(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['isSuspended'] == true;
  }

  Future<void> ensureUserAllowed(String uid) async {
    if (await isSuspended(uid)) {
      await signOutSuspendedUser();
      throw const SuspensionException();
    }
  }

  Future<void> ensureCurrentUserAllowed() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User not logged in');
    }

    await ensureUserAllowed(uid);
  }

  Future<void> signOutSuspendedUser() async {
    try {
      await _authService.signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }
}
