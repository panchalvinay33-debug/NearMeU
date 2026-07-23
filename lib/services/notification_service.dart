import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../security/notification_route.dart';
import 'notification_navigation_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  String? _registeredUid;
  String? _registeredToken;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      'nearmeu_notifications',
      'NearMeU Notifications',
      description: 'Private chat notifications',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedRemoteMessage,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Notification-open listener failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      _handleTokenRefresh,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'FCM token refresh listener failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthState,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Notification auth listener failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    await _queueInitialNotificationRoute();
    await _handleAuthState(_auth.currentUser);
  }

  Future<void> unregisterCurrentDevice() async {
    final user = _auth.currentUser;
    final token = _registeredToken ?? await _messaging.getToken();
    if (user == null || token == null || token.isEmpty) {
      await _revokeLocalToken();
      return;
    }

    try {
      await _functions.httpsCallable('unregisterDeviceToken').call<void>(
        <String, dynamic>{'token': token},
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      developer.log(
        'FCM device unregister failed: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      developer.log(
        'FCM device unregister failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      await _revokeLocalToken();
    }
  }

  Future<void> unregisterAllDevicesForCurrentUser() async {
    if (_auth.currentUser == null) {
      await _revokeLocalToken();
      return;
    }

    try {
      await _functions
          .httpsCallable('unregisterAllDeviceTokens')
          .call<void>();
    } on FirebaseFunctionsException catch (error, stackTrace) {
      developer.log(
        'All-device unregister failed: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'All-device unregister failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      await _revokeLocalToken();
    }
  }

  Future<void> _queueInitialNotificationRoute() async {
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      NotificationNavigationService.instance.queueChatId(
        launchDetails?.notificationResponse?.payload,
      );
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedRemoteMessage(initialMessage);
    }
  }

  void _handleLocalNotificationResponse(NotificationResponse response) {
    NotificationNavigationService.instance.queueChatId(response.payload);
  }

  void _handleOpenedRemoteMessage(RemoteMessage message) {
    NotificationNavigationService.instance.queueChatId(
      NotificationRoute.chatIdFromData(message.data),
    );
  }

  Future<void> _handleAuthState(User? user) async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    _registeredUid = null;
    _registeredToken = null;

    if (user == null) {
      NotificationNavigationService.instance.setAppShellReady(false);
      return;
    }

    _profileSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((profile) {
          final data = profile.data();
          if (!profile.exists || data == null || data['isSuspended'] == true) {
            return;
          }
          unawaited(_registerCurrentToken(user.uid));
        }, onError: (Object error, StackTrace stackTrace) {
          developer.log(
            'Notification profile listener failed',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  Future<void> _registerCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _registerToken(uid, token);
  }

  Future<void> _handleTokenRefresh(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;

    final profile = await _firestore.collection('users').doc(user.uid).get();
    if (!profile.exists || profile.data()?['isSuspended'] == true) return;

    final previousToken = _registeredToken;
    if (previousToken != null && previousToken != token) {
      try {
        await _functions.httpsCallable('unregisterDeviceToken').call<void>(
          <String, dynamic>{'token': previousToken},
        );
      } catch (error, stackTrace) {
        developer.log(
          'Old FCM device token cleanup failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    await _registerToken(user.uid, token);
  }

  Future<void> _registerToken(String uid, String token) async {
    if (_registeredUid == uid && _registeredToken == token) return;

    try {
      await _functions.httpsCallable('registerDeviceToken').call<void>(
        <String, dynamic>{
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
      _registeredUid = uid;
      _registeredToken = token;
      developer.log('FCM device registered for authenticated user.');
    } on FirebaseFunctionsException catch (error, stackTrace) {
      developer.log(
        'FCM device registration failed: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      developer.log(
        'FCM device registration failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _revokeLocalToken() async {
    try {
      await _messaging.deleteToken();
    } catch (error, stackTrace) {
      developer.log(
        'Local FCM token revocation failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _registeredUid = null;
      _registeredToken = null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final chatId = NotificationRoute.chatIdFromData(message.data);
    if (notification == null || chatId == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nearmeu_notifications',
          'NearMeU Notifications',
          channelDescription: 'Private chat notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: chatId,
    );
  }

  Future<void> dispose() async {
    await _profileSubscription?.cancel();
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    _profileSubscription = null;
    _authSubscription = null;
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedMessageSubscription = null;
    _initialized = false;
  }
}
