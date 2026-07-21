import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/login_screen.dart';
import 'suspension_service.dart';

class SuspensionGuard extends StatefulWidget {
  const SuspensionGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SuspensionGuard> createState() => _SuspensionGuardState();
}

class _SuspensionGuardState extends State<SuspensionGuard> {
  final SuspensionService _suspensionService = SuspensionService();
  StreamSubscription<AppUser?>? _subscription;
  bool _handlingSuspension = false;

  @override
  void initState() {
    super.initState();
    _subscription = _suspensionService.streamCurrentUser().listen((user) {
      if (user?.isSuspended == true) {
        _handleSuspension();
      }
    });
  }

  Future<void> _handleSuspension() async {
    if (_handlingSuspension) return;
    _handlingSuspension = true;

    await _suspensionService.signOutSuspendedUser();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Your account has been suspended. Please contact support.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
