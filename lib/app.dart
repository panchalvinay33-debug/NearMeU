import 'package:flutter/material.dart';

import 'screens/auth_gate_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class NearMeUApp extends StatefulWidget {
  const NearMeUApp({super.key});

  @override
  State<NearMeUApp> createState() => _NearMeUAppState();
}

class _NearMeUAppState extends State<NearMeUApp> {
  final ThemeController _themeController = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NearMeU',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.themeMode,
          home: const AuthGateScreen(),
        );
      },
    );
  }
}
