import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Keeps the signed-in user's Firestore presence in sync with authentication
/// and the app lifecycle.
///
/// This deliberately updates only an existing profile document so a partial
/// user profile is never created before onboarding has completed.
class PresenceCoordinator with WidgetsBindingObserver {
  PresenceCoordinator._();

  static final PresenceCoordinator instance = PresenceCoordinator._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  Timer? _profileRetryTimer;
  String? _activeUid;
  bool _initialized = false;
  bool _writeInProgress = false;
  bool? _lastWrittenOnlineState;
  int _profileRetryCount = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthChanged,
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          developer.log(
            'Presence auth listener failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );

    await _handleAuthChanged(_auth.currentUser);
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _profileRetryTimer?.cancel();
    _profileRetryTimer = null;
    await _authSubscription?.cancel();
    _authSubscription = null;
    _initialized = false;
  }

  Future<void> _handleAuthChanged(User? user) async {
    final previousUid = _activeUid;
    final nextUid = user?.uid;

    _profileRetryTimer?.cancel();
    _profileRetryTimer = null;
    _profileRetryCount = 0;

    if (previousUid != null && previousUid != nextUid) {
      await _writePresence(previousUid, isOnline: false, force: true);
    }

    _activeUid = nextUid;
    _lastWrittenOnlineState = null;

    if (nextUid != null) {
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      final shouldBeOnline = lifecycleState == null ||
          lifecycleState == AppLifecycleState.resumed;
      await _writePresence(nextUid, isOnline: shouldBeOnline, force: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = _activeUid;
    if (uid == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_writePresence(uid, isOnline: true));
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _profileRetryTimer?.cancel();
        unawaited(_writePresence(uid, isOnline: false));
        break;
    }
  }

  Future<void> markCurrentUserOffline() async {
    final uid = _auth.currentUser?.uid ?? _activeUid;
    if (uid == null) return;
    _profileRetryTimer?.cancel();
    await _writePresence(uid, isOnline: false, force: true);
  }

  Future<void> markCurrentUserOnline() async {
    final uid = _auth.currentUser?.uid ?? _activeUid;
    if (uid == null) return;
    await _writePresence(uid, isOnline: true, force: true);
  }

  Future<void> _writePresence(
    String uid, {
    required bool isOnline,
    bool force = false,
  }) async {
    if (_writeInProgress) return;
    if (!force && _lastWrittenOnlineState == isOnline) return;

    _writeInProgress = true;
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snapshot = await userRef.get();

      // A new Google-authenticated account may not have its profile document
      // until onboarding is submitted. Retry briefly instead of creating a
      // partial profile or leaving the new account permanently offline.
      if (!snapshot.exists) {
        if (isOnline && uid == _activeUid && _profileRetryCount < 15) {
          _profileRetryCount += 1;
          _profileRetryTimer?.cancel();
          _profileRetryTimer = Timer(const Duration(seconds: 2), () {
            unawaited(_writePresence(uid, isOnline: true, force: true));
          });
        }
        return;
      }

      _profileRetryTimer?.cancel();
      _profileRetryTimer = null;
      _profileRetryCount = 0;

      await userRef.update(<String, Object>{
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      _lastWrittenOnlineState = isOnline;

      if (kDebugMode) {
        developer.log('Presence updated: online=$isOnline');
      }
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        developer.log(
          'Presence update failed: ${error.code}',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } finally {
      _writeInProgress = false;
    }
  }
}
