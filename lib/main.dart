import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate_screen.dart';
import 'security/screen_capture_guard.dart';
import 'security/suspension_guard.dart';
import 'services/notification_navigation_service.dart';
import 'services/notification_service.dart';
import 'services/observability_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_version_gate.dart';
import 'widgets/presence_lifecycle.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
  );

  final observability = ObservabilityService.instance;
  await observability.initialize();
  observability.installGlobalErrorHandlers();

  await observability.trace('startup_services', () async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    NotificationNavigationService.instance.attachNavigatorKey(rootNavigatorKey);
    await NotificationService.instance.initialize();
  });
  await observability.logEvent('app_services_ready');

  runApp(const NearMeUApp());
}

class NearMeUApp extends StatelessWidget {
  const NearMeUApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      navigatorKey: rootNavigatorKey,
      navigatorObservers: ObservabilityService.instance.navigatorObservers,
      title: 'NearMeU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final textScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.30,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: textScaler),
          child: ScrollConfiguration(
            behavior: const _NearMeUScrollBehavior(),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const AppVersionGate(
        child: PresenceLifecycle(
          child: SuspensionGuard(child: AuthGateScreen()),
        ),
      ),
    );

    // Screenshots are intentionally allowed in debug/testing builds so
    // testers can report visual and authentication issues. Production
    // release builds remain protected by the native secure-screen guard.
    return kReleaseMode ? ScreenCaptureGuard(child: app) : app;
  }
}

class _NearMeUScrollBehavior extends MaterialScrollBehavior {
  const _NearMeUScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
