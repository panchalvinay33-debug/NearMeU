import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'nickname_screen.dart';
import 'login_screen.dart';
import 'nearby_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    // Small delay so Firebase Auth has time to restore the session.
    await Future.delayed(const Duration(milliseconds: 700));

    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    // No logged-in user -> Login Screen
    if (firebaseUser == null) {
      _goTo(const LoginScreen());
      return;
    }

    try {
      // Get current user's Firestore profile.
      final AppUser? savedUser =
          await _userService.getUser(firebaseUser.uid);

      if (!mounted) return;

      // =========================================================
      // SECURITY CHECK: SUSPENDED ACCOUNT
      // =========================================================
      if (savedUser != null && savedUser.isSuspended) {
        await _handleSuspendedAccount();
        return;
      }

      // =========================================================
      // EXISTING NORMAL APP FLOW
      // =========================================================
      if (savedUser != null &&
          _userService.isProfileComplete(savedUser)) {
        _goTo(NearbyScreen());
        return;
      }

      // User is authenticated but profile is incomplete/new.
      _goTo(
        NicknameScreen(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
        ),
      );
    } catch (e) {
      // Fail safely instead of allowing access when account
      // verification could not be completed.
      try {
        await _authService.logout();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) return;

      _goToLoginWithMessage(
        'Unable to verify your account. Please sign in again.',
      );
    }
  }

  Future<void> _handleSuspendedAccount() async {
    // Sign out from Google + Firebase Auth.
    try {
      await _authService.logout();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;

    // Send user back to Login Screen and show suspension message.
    _goToLoginWithMessage(
      'Your account has been suspended. Please contact support.',
      isSuspended: true,
    );
  }

  void _goToLoginWithMessage(
    String message, {
    bool isSuspended = false,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );

    // Show message after LoginScreen has been rendered.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.maybeOf(context);

      messenger?.clearSnackBars();

      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isSuspended ? Colors.red.shade700 : Colors.red.shade600,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _goTo(Widget screen) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff0B0B0B),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 90,
                  color: Colors.purpleAccent,
                ),
                SizedBox(height: 20),
                Text(
                  'NearMeU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Checking your account...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 28),
                CircularProgressIndicator(
                  color: Colors.purpleAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}