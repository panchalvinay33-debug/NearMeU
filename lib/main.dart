import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'security/suspension_guard.dart';
import 'services/notification_navigation_service.dart';
import 'services/notification_service.dart';
import 'services/observability_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_version_gate.dart';
import 'widgets/message_delivery_lifecycle.dart';
import 'widgets/presence_lifecycle.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final observability = ObservabilityService.instance;
  await observability.initialize();
  observability.installGlobalErrorHandlers();

  var appCheckReady = false;
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
    );
    appCheckReady = true;
  } catch (error, stackTrace) {
    await observability.recordNonFatal(
      error,
      stackTrace,
      reason: 'app_check_activation_failed',
    );
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  NotificationNavigationService.instance.attachNavigatorKey(rootNavigatorKey);

  var notificationsReady = false;
  try {
    await observability.trace('startup_notifications', () async {
      await NotificationService.instance.initialize();
    });
    notificationsReady = true;
  } catch (error, stackTrace) {
    await observability.recordNonFatal(
      error,
      stackTrace,
      reason: 'notification_initialization_failed',
    );
  }

  await observability.logEvent(
    'app_services_ready',
    parameters: <String, Object>{
      'app_check_ready': appCheckReady ? 1 : 0,
      'notifications_ready': notificationsReady ? 1 : 0,
    },
  );

  runApp(const NearMeUApp());
}

class NearMeUApp extends StatelessWidget {
  const NearMeUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          child: MessageDeliveryLifecycle(
            child: SuspensionGuard(child: LoginScreen()),
          ),
        ),
      ),
    );
  }
}

class _NearMeUScrollBehavior extends MaterialScrollBehavior {
  const _NearMeUScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
