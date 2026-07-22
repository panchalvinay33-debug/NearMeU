import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Synchronizes the signed-in user's best-effort Firestore presence with the
/// authentication state and Flutter application lifecycle.
///
/// Presence never creates a profile document. A newly authenticated account is
/// retried briefly until onboarding creates its complete profile.
class PresenceCoordinator with WidgetsBindingObserver {
  PresenceCoordinator._();

  static final PresenceCoordinator instance = PresenceCoordinator._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  Timer? _profileRetryTimer;
  Future<void> _writeQueue = Future<void>.value();
  String? _activeUid;
  bool _initialized = false;
  bool? _lastWrittenOnlineState;
  int _profileRetryCount = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _auth.authStateChanges().listen(
      (user) => unawaited(_handleAuthChanged(user)),
      onError: (Object error, StackTrace stackTrace) {
        _debugLog(
          'Presence authentication listener failed',
          error,
          stackTrace,
        );
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

  Future<void> markCurrentUserOffline() async {
    final uid = _auth.currentUser?.uid ?? _activeUid;
    if (uid == null) return;
    _profileRetryTimer?.cancel();
    await _enqueuePresence(uid, isOnline: false, force: true);
  }

  Future<void> markCurrentUserOnline() async {
    final uid = _auth.currentUser?.uid ?? _activeUid;
    if (uid == null) return;
    await _enqueuePresence(uid, isOnline: true, force: true);
  }

  Future<void> _handleAuthChanged(User? user) async {
    final previousUid = _activeUid;
    final nextUid = user?.uid;

    _profileRetryTimer?.cancel();
    _profileRetryTimer = null;
    _profileRetryCount = 0;

    if (previousUid != null && previousUid != nextUid) {
      await _enqueuePresence(previousUid, isOnline: false, force: true);
    }

    _activeUid = nextUid;
    _lastWrittenOnlineState = null;

    if (nextUid == null) return;

    final state = WidgetsBinding.instance.lifecycleState;
    final shouldBeOnline = state == null || state == AppLifecycleState.resumed;
    await _enqueuePresence(
      nextUid,
      isOnline: shouldBeOnline,
      force: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = _activeUid;
    if (uid == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_enqueuePresence(uid, isOnline: true));
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _profileRetryTimer?.cancel();
        unawaited(_enqueuePresence(uid, isOnline: false));
        break;
    }
  }

  Future<void> _enqueuePresence(
    String uid, {
    required bool isOnline,
    bool force = false,
  }) {
    final completer = Completer<void>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        await _writePresence(uid, isOnline: isOnline, force: force);
        completer.complete();
      } catch (error, stackTrace) {
        _debugLog('Presence queue failed', error, stackTrace);
        completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> _writePresence(
    String uid, {
    required bool isOnline,
    required bool force,
  }) async {
    if (!force && uid == _activeUid && _lastWrittenOnlineState == isOnline) {
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        if (isOnline && uid == _activeUid && _profileRetryCount < 15) {
          _profileRetryCount += 1;
          _profileRetryTimer?.cancel();
          _profileRetryTimer = Timer(const Duration(seconds: 2), () {
            unawaited(
              _enqueuePresence(uid, isOnline: true, force: true),
            );
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

      if (uid == _activeUid) {
        _lastWrittenOnlineState = isOnline;
      }
      _debugLog('Presence updated: online=$isOnline');
    } on FirebaseException catch (error, stackTrace) {
      _debugLog(
        'Presence update failed: ${error.code}',
        error,
        stackTrace,
      );
    }
  }

  void _debugLog(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;
    developer.log(
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
