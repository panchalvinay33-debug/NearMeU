import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'nearmeu_notifications';
  static const String _channelName = 'NearMeU Notifications';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  Timer? _registrationRetryTimer;
  bool _initialized = false;
  int _registrationRetryCount = 0;
  String? _registeredUid;
  String? _registeredToken;

  Future<void> initializeInfrastructure() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _localNotifications.initialize(settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Private chat and NearMeU service notifications',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) => unawaited(_registerTokenForCurrentUser(token)),
      onError: (Object error, StackTrace stackTrace) {
        _debugLog('FCM token listener failed', error, stackTrace);
      },
    );
    _authSubscription = _auth.authStateChanges().listen(
      (user) => unawaited(_handleAuthChanged(user)),
      onError: (Object error, StackTrace stackTrace) {
        _debugLog('Notification auth listener failed', error, stackTrace);
      },
    );

    await _handleAuthChanged(_auth.currentUser);
  }

  Future<NotificationSettings> requestPermissionAndRegister() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerTokenForCurrentUser(token);
      }
    }

    return settings;
  }

  Future<void> unregisterCurrentDevice() async {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = null;

    final uid = _registeredUid ?? _auth.currentUser?.uid;
    final token = _registeredToken ?? await _messaging.getToken();
    if (uid == null || token == null || token.isEmpty) return;

    await _deleteDeviceToken(uid, token);
    _registeredUid = null;
    _registeredToken = null;
  }

  Future<void> dispose() async {
    _registrationRetryTimer?.cancel();
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    _authSubscription = null;
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _initialized = false;
  }

  Future<void> _handleAuthChanged(User? user) async {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = null;
    _registrationRetryCount = 0;

    if (user == null) {
      _registeredUid = null;
      _registeredToken = null;
      return;
    }

    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerTokenForCurrentUser(token);
    }
  }

  Future<void> _registerTokenForCurrentUser(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token.isEmpty) return;
    if (_registeredUid == uid && _registeredToken == token) return;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final profile = await userRef.get();
      if (!profile.exists) {
        _scheduleRegistrationRetry(token);
        return;
      }

      await userRef
          .collection('devices')
          .doc(_tokenDocumentId(token))
          .set(<String, Object?>{
        'token': token,
        'platform': 'android',
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _registrationRetryTimer?.cancel();
      _registrationRetryTimer = null;
      _registrationRetryCount = 0;
      _registeredUid = uid;
      _registeredToken = token;
      _debugLog('FCM device token registered');
    } on FirebaseException catch (error, stackTrace) {
      _debugLog(
        'FCM token registration failed: ${error.code}',
        error,
        stackTrace,
      );
      _scheduleRegistrationRetry(token);
    }
  }

  void _scheduleRegistrationRetry(String token) {
    if (_registrationRetryCount >= 10 || _auth.currentUser == null) return;
    _registrationRetryCount += 1;
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = Timer(const Duration(seconds: 3), () {
      unawaited(_registerTokenForCurrentUser(token));
    });
  }

  Future<void> _deleteDeviceToken(String uid, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(_tokenDocumentId(token))
          .delete();
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'not-found') return;
      _debugLog(
        'FCM token removal failed: ${error.code}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.messageId?.hashCode ?? notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.private,
        ),
      ),
      payload: message.data['chatId'] as String?,
    );
  }

  String _tokenDocumentId(String token) =>
      base64Url.encode(utf8.encode(token)).replaceAll('=', '');

  void _debugLog(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;
    developer.log(message, error: error, stackTrace: stackTrace);
  }
}
