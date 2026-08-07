import 'dart:async';
import 'dart:developer' as developer;

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
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuthService _authService;

  static const Duration _serverCheckTimeout = Duration(seconds: 3);
  static const Duration _cacheCheckTimeout = Duration(seconds: 1);

  Stream<AppUser?> streamCurrentUser() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<AppUser?>.value(null);
      }

      return _firestore.collection('users').doc(user.uid).snapshots().map((
        doc,
      ) {
        if (!doc.exists || doc.data() == null) return null;
        return AppUser.fromMap(doc.data()!, doc.id);
      });
    });
  }

  bool _isTransientFirestoreError(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'cancelled' ||
        error.code == 'unknown';
  }

  Future<bool> _cachedSuspensionState(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      final cachedDocument = await reference
          .get(const GetOptions(source: Source.cache))
          .timeout(_cacheCheckTimeout);
      return cachedDocument.exists &&
          cachedDocument.data()?['isSuspended'] == true;
    } catch (_) {
      // Firestore rules and callable functions remain the final authority.
      // A missing cache must never freeze ordinary app operations.
      return false;
    }
  }

  Future<bool> isSuspended(String uid) async {
    final reference = _firestore.collection('users').doc(uid);

    try {
      final document = await reference.get().timeout(_serverCheckTimeout);
      return document.exists && document.data()?['isSuspended'] == true;
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Suspension server check timed out; using cached state',
        error: error,
        stackTrace: stackTrace,
      );
      return _cachedSuspensionState(reference);
    } on FirebaseException catch (error, stackTrace) {
      if (!_isTransientFirestoreError(error)) rethrow;

      developer.log(
        'Suspension check is using cached data while Firestore is unavailable',
        error: error,
        stackTrace: stackTrace,
      );
      return _cachedSuspensionState(reference);
    }
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
