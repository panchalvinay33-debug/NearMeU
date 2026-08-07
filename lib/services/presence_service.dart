import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
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
  Timer? _heartbeatTimer;
  Timer? _retryTimer;

  String? _activeUid;
  bool? _lastPublishedOnline;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _started = false;
  int _consecutiveFailures = 0;

  static const Duration _publishTimeout = Duration(seconds: 5);

  void start() {
    if (_started) return;
    _started = true;
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChange);
    unawaited(_handleAuthChange(_auth.currentUser));
  }

  void updateLifecycle(AppLifecycleState state) {
    _lifecycleState = state;
    unawaited(_publishDesiredState(force: state == AppLifecycleState.resumed));
  }

  Future<void> goOfflineBeforeSignOut() async {
    _stopHeartbeat();
    _cancelRetry();
    final uid = _auth.currentUser?.uid ?? _activeUid;
    if (uid == null) return;
    await _publish(online: false, uid: uid, force: true);
    _lastPublishedOnline = null;
  }

  Future<void> restoreCurrentState() => _publishDesiredState(force: true);

  Future<void> _handleAuthChange(User? user) async {
    _stopHeartbeat();
    _cancelRetry();
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    _activeUid = user?.uid;
    _lastPublishedOnline = null;
    _consecutiveFailures = 0;

    if (user == null) return;

    _profileSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (profile) {
            if (!profile.exists) return;

            final desiredOnline =
                _lifecycleState == AppLifecycleState.resumed;
            final actualOnline = profile.data()?['isOnline'] == true;

            if (actualOnline != desiredOnline) {
              _lastPublishedOnline = null;
              unawaited(_publishDesiredState(force: true));
              return;
            }

            // A server-backed snapshot confirms queued local presence writes
            // eventually reached Firestore after a weak/offline connection.
            if (!profile.metadata.hasPendingWrites) {
              _consecutiveFailures = 0;
              _cancelRetry();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            developer.log(
              'Presence profile listener failed',
              error: error,
              stackTrace: stackTrace,
            );
            _scheduleRetry();
          },
        );

    await _publishDesiredState(force: true);
  }

  Future<void> _publishDesiredState({bool force = false}) async {
    final uid = _activeUid ?? _auth.currentUser?.uid;
    if (uid == null) {
      _stopHeartbeat();
      _cancelRetry();
      return;
    }

    final online = _lifecycleState == AppLifecycleState.resumed;
    await _publish(online: online, uid: uid, force: force);
    _configureHeartbeat(uid: uid, online: online);
  }

  void _configureHeartbeat({required String uid, required bool online}) {
    if (!online) {
      _stopHeartbeat();
      return;
    }

    if (_heartbeatTimer != null) return;

    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: AppConstants.presenceHeartbeatMinutes),
      (_) {
        unawaited(_publish(online: true, uid: uid, force: true));
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _scheduleRetry() {
    if (_retryTimer != null) return;
    final seconds = switch (_consecutiveFailures) {
      <= 0 => 3,
      1 => 8,
      2 => 15,
      _ => 30,
    };
    _retryTimer = Timer(Duration(seconds: seconds), () {
      _retryTimer = null;
      unawaited(_publishDesiredState(force: true));
    });
  }

  Future<void> _publish({
    required bool online,
    required String uid,
    bool force = false,
  }) async {
    if (!force && _lastPublishedOnline == online) return;

    try {
      // Do not hydrate the full profile here. Presence is a tiny lifecycle
      // write and must not depend on private-profile, block-list, migration,
      // geocoding, or other network reads. Firestore security rules remain the
      // server-side authority for whether this user may update presence.
      await _userService
          .setOnlineStatus(uid, online)
          .timeout(_publishTimeout);
      _lastPublishedOnline = online;
      _consecutiveFailures = 0;
      _cancelRetry();
    } catch (error, stackTrace) {
      _lastPublishedOnline = null;
      _consecutiveFailures += 1;
      developer.log(
        'Presence update failed; retry scheduled',
        error: error,
        stackTrace: stackTrace,
      );
      _scheduleRetry();
    }
  }

  Future<void> dispose() async {
    _stopHeartbeat();
    _cancelRetry();
    await _profileSubscription?.cancel();
    await _authSubscription?.cancel();
    _profileSubscription = null;
    _authSubscription = null;
    _started = false;
  }
}
