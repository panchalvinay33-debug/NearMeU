import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import 'profile_schema_repair_service.dart';
import 'user_service.dart';

class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final ProfileSchemaRepairService _profileRepair = ProfileSchemaRepairService();

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

  bool get _shouldBeOnline =>
      _lifecycleState == AppLifecycleState.resumed ||
      _lifecycleState == AppLifecycleState.inactive;

  void start() {
    if (_started) return;
    _started = true;
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChange);
    unawaited(_handleAuthChange(_auth.currentUser));
  }

  void updateLifecycle(AppLifecycleState state) {
    final previous = _lifecycleState;
    _lifecycleState = state;

    if (state == AppLifecycleState.inactive) return;

    final force = state == AppLifecycleState.resumed || previous != state;
    unawaited(_publishDesiredState(force: force));
  }

  void touchForeground() {
    if (!_shouldBeOnline) return;
    unawaited(_publishDesiredState(force: true));
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

            final desiredOnline = _shouldBeOnline;
            final actualOnline = profile.data()?['isOnline'] == true;

            if (actualOnline != desiredOnline) {
              _lastPublishedOnline = null;
              unawaited(_publishDesiredState(force: true));
              return;
            }

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

    final online = _shouldBeOnline;
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

  Future<void> _writePresence(String uid, bool online) {
    return _userService.setOnlineStatus(uid, online).timeout(_publishTimeout);
  }

  Future<void> _publish({
    required bool online,
    required String uid,
    bool force = false,
  }) async {
    if (!force && _lastPublishedOnline == online) return;

    try {
      await _writePresence(uid, online);
      _lastPublishedOnline = online;
      _consecutiveFailures = 0;
      _cancelRetry();
    } catch (error, stackTrace) {
      var repairedAndPublished = false;
      if (error is FirebaseException && error.code == 'permission-denied') {
        final repaired = await _profileRepair.repairCurrentProfile();
        if (repaired) {
          try {
            await _writePresence(uid, online);
            repairedAndPublished = true;
          } catch (retryError, retryStackTrace) {
            developer.log(
              'Presence retry after profile repair failed',
              error: retryError,
              stackTrace: retryStackTrace,
            );
          }
        }
      }

      if (repairedAndPublished) {
        _lastPublishedOnline = online;
        _consecutiveFailures = 0;
        _cancelRetry();
        return;
      }

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
