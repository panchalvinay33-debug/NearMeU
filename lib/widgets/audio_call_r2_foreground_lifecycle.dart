import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/audio_call_r2_screen.dart';
import '../services/audio_call_r2_service.dart';

class AudioCallR2ForegroundLifecycle extends StatefulWidget {
  const AudioCallR2ForegroundLifecycle({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AudioCallR2ForegroundLifecycle> createState() =>
      _AudioCallR2ForegroundLifecycleState();
}

class _AudioCallR2ForegroundLifecycleState
    extends State<AudioCallR2ForegroundLifecycle>
    with WidgetsBindingObserver {
  final AudioCallR2Service _service = AudioCallR2Service();
  Timer? _timer;
  StreamSubscription<User?>? _authSubscription;
  bool _checking = false;
  bool _screenOpen = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  String? _lastOpenedCallId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _timer?.cancel();
        _lastOpenedCallId = null;
        return;
      }
      _startPolling();
    });
    if (FirebaseAuth.instance.currentUser != null) _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_checkIncoming()),
    );
    unawaited(_checkIncoming());
  }

  Future<void> _checkIncoming() async {
    if (
        _checking ||
        _screenOpen ||
        _lifecycleState != AppLifecycleState.resumed ||
        FirebaseAuth.instance.currentUser == null) {
      return;
    }

    _checking = true;
    try {
      final incoming = await _service.getIncomingCall();
      if (!mounted || incoming == null) return;
      if (_lastOpenedCallId == incoming.callId) return;

      final navigator = widget.navigatorKey.currentState;
      if (navigator == null) return;

      _screenOpen = true;
      _lastOpenedCallId = incoming.callId;
      await navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AudioCallR2Screen.incoming(callId: incoming.callId),
          fullscreenDialog: true,
        ),
      );
    } catch (_) {
      // Foreground discovery is best-effort. The next interval retries safely.
    } finally {
      _screenOpen = false;
      _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkIncoming());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
