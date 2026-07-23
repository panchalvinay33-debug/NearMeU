import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate_screen.dart';
import 'security/suspension_guard.dart';
import 'services/notification_navigation_service.dart';
import 'services/notification_service.dart';
import 'widgets/presence_lifecycle.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
    appleProvider: kReleaseMode
        ? AppleProvider.appAttestWithDeviceCheckFallback
        : AppleProvider.debug,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  NotificationNavigationService.instance.attachNavigatorKey(rootNavigatorKey);
  await NotificationService.instance.initialize();

  runApp(const NearMeUApp());
}

class NearMeUApp extends StatelessWidget {
  const NearMeUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'NearMeU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0B0B0B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PresenceLifecycle(
        child: SuspensionGuard(child: AuthGateScreen()),
      ),
    );
  }
}
