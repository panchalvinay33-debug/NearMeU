import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import 'gender_screen.dart';
import 'login_screen.dart';
import 'nearby_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    await Future.delayed(const Duration(milliseconds: 700));

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (firebaseUser == null) {
      _goTo(const LoginScreen());
      return;
    }

    try {
      final AppUser? savedUser = await _userService.getUser(firebaseUser.uid);

      if (!mounted) return;

      if (savedUser != null && _userService.isProfileComplete(savedUser)) {
        _goTo(NearbyScreen());
      } else {
        _goTo(
          GenderScreen(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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