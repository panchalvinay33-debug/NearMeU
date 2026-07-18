import 'package:flutter/material.dart';
import 'screens/auth_gate_screen.dart';

class NearMeUApp extends StatelessWidget {
  const NearMeUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NearMeU',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8A2BE2),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGateScreen(),
    );
  }
}