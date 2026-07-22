import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'user_service.dart';

class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  String? _activeUid;
  bool? _lastPublishedOnline;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChange);
    unawaited(_handleAuthChange(_auth.currentUser));
  }

  void updateLifecycle(AppLifecycleState state) {
    _lifecycleState = state;
    unawaited(_publishDesiredState());
  }

  Future<void> goOfflineBeforeSignOut() async {
    final uid = _auth.currentUser?.uid ?? _activeUid;
    if (uid == null) return;
    await _publish(online: false, uid: uid, force: true);
    _lastPublishedOnline = null;
  }

  Future<void> _handleAuthChange(User? user) async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    _activeUid = user?.uid;
    _lastPublishedOnline = null;

    if (user == null) return;

    _profileSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((profile) {
          if (profile.exists) unawaited(_publishDesiredState());
        }, onError: (Object error, StackTrace stackTrace) {
          developer.log(
            'Presence profile listener failed',
            error: error,
            stackTrace: stackTrace,
          );
        });

    await _publishDesiredState();
  }

  Future<void> _publishDesiredState() async {
    final uid = _activeUid ?? _auth.currentUser?.uid;
    if (uid == null) return;
    await _publish(
      online: _lifecycleState == AppLifecycleState.resumed,
      uid: uid,
    );
  }

  Future<void> _publish({
    required bool online,
    required String uid,
    bool force = false,
  }) async {
    if (!force && _lastPublishedOnline == online) return;

    try {
      final user = await _userService.getUser(uid);
      if (user == null || user.isSuspended) return;
      await _userService.setOnlineStatus(uid, online);
      _lastPublishedOnline = online;
    } catch (error, stackTrace) {
      developer.log(
        'Presence update failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> dispose() async {
    await _profileSubscription?.cancel();
    await _authSubscription?.cancel();
    _profileSubscription = null;
    _authSubscription = null;
    _started = false;
  }
}
