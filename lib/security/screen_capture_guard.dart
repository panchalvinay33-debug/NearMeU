import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../services/user_service.dart';

class ScreenCaptureGuard extends StatefulWidget {
  const ScreenCaptureGuard({super.key, required this.child});

  final Widget child;

  @override
  State<ScreenCaptureGuard> createState() => _ScreenCaptureGuardState();
}

class _ScreenCaptureGuardState extends State<ScreenCaptureGuard>
    with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel(
    'com.nearmeu.nearmeu/screen_security',
  );

  final UserService _userService = UserService();
  StreamSubscription<User?>? _authSubscription;
  bool _captureBlocked = true;
  int _verificationGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setCaptureBlocked(true));
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _verifyCurrentAccount,
      onError: (_) => unawaited(_setCaptureBlocked(true)),
    );
    unawaited(_verifyCurrentAccount(FirebaseAuth.instance.currentUser));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_verifyCurrentAccount(FirebaseAuth.instance.currentUser));
    }
  }

  Future<void> _verifyCurrentAccount(User? firebaseUser) async {
    final generation = ++_verificationGeneration;

    // Fail closed while account state is absent or being verified.
    await _setCaptureBlocked(true);
    if (firebaseUser == null) return;

    try {
      final user = await _userService.getUser(firebaseUser.uid);
      if (!mounted || generation != _verificationGeneration) return;
      await _setCaptureBlocked(user?.isAdmin != true);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Screen capture admin verification failed: $error');
      }
      if (!mounted || generation != _verificationGeneration) return;
      await _setCaptureBlocked(true);
    }
  }

  Future<void> _setCaptureBlocked(bool blocked) async {
    if (_captureBlocked == blocked && blocked) {
      // Re-apply the secure flag after activity/lifecycle changes.
    } else {
      _captureBlocked = blocked;
    }

    try {
      await _channel.invokeMethod<void>('setScreenCaptureBlocked', {
        'blocked': blocked,
      });
    } on MissingPluginException {
      // Non-Android test platforms do not expose the native channel.
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to update screen capture protection: $error');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verificationGeneration += 1;
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
