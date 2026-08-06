import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/audio_call_service.dart';
import '../services/notification_navigation_service.dart';

class ActiveAudioCallLifecycle extends StatefulWidget {
  const ActiveAudioCallLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<ActiveAudioCallLifecycle> createState() =>
      _ActiveAudioCallLifecycleState();
}

class _ActiveAudioCallLifecycleState extends State<ActiveAudioCallLifecycle>
    with WidgetsBindingObserver {
  final AudioCallService _calls = AudioCallService();
  StreamSubscription<User?>? _authSubscription;
  Timer? _retryTimer;
  bool _checking = false;
  String? _checkedUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        _checkedUid = null;
        _retryTimer?.cancel();
        if (user != null) unawaited(_recover(force: true));
      },
    );
    if (FirebaseAuth.instance.currentUser != null) {
      unawaited(_recover(force: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recover(force: true));
    }
  }

  Future<void> _recover({bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _checking) return;
    if (!force && _checkedUid == user.uid) return;
    _checking = true;
    try {
      final session = await _calls.getPendingCall();
      _checkedUid = user.uid;
      final call = session?.call;
      if (call == null || call.isTerminal) return;
      if (call.callerId != user.uid && call.calleeId != user.uid) return;
      NotificationNavigationService.instance.queueAudioCallId(call.callId);
    } catch (_) {
      _retryTimer?.cancel();
      _retryTimer = Timer(
        const Duration(seconds: 5),
        () => unawaited(_recover(force: true)),
      );
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
