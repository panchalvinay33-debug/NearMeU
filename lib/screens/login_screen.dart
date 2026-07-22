import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../security/suspension_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'gender_screen.dart';
import 'nearby_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool isLoading = false;

  Future<void> _handleGoogleLogin() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) return;

      final User firebaseUser = result.user!;
      final AppUser? savedUser = await _userService.getUser(firebaseUser.uid);
      if (!mounted) return;

      if (savedUser != null && savedUser.isSuspended) {
        await SuspensionService().signOutSuspendedUser();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your account has been suspended. Please contact support.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      if (savedUser != null && _userService.isProfileComplete(savedUser)) {
        unawaited(
          NotificationService.instance.requestPermissionAndRegister(),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NearbyScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GenderScreen(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.location_on_rounded,
                size: 90,
                color: Colors.purpleAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'NearMeU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Private and safe nearby chatting and dating app',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleLogin,
                  icon: isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.login_rounded),
                  label: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
