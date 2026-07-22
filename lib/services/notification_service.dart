import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  bool _initialized = false;
  String? _registeredUid;
  String? _registeredToken;

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

    await _localNotifications.initialize(settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Chat and NearMeU notifications',
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
      (token) => _registerTokenForCurrentUser(token),
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          developer.log(
            'FCM token refresh listener failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );

    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthChanged,
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          developer.log(
            'Notification auth listener failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );

    await _handleAuthChanged(_auth.currentUser);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    _authSubscription = null;
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _initialized = false;
  }

  Future<void> _handleAuthChanged(User? user) async {
    final previousUid = _registeredUid;
    final previousToken = _registeredToken;

    if (previousUid != null &&
        previousToken != null &&
        previousUid != user?.uid) {
      await _deleteDeviceToken(previousUid, previousToken);
      _registeredUid = null;
      _registeredToken = null;
    }

    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerTokenForCurrentUser(token);
    }
  }

  Future<void> _registerTokenForCurrentUser(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token.isEmpty) return;

    if (_registeredUid == uid && _registeredToken == token) return;

    if (_registeredUid != null &&
        _registeredToken != null &&
        (_registeredUid != uid || _registeredToken != token)) {
      await _deleteDeviceToken(_registeredUid!, _registeredToken!);
    }

    try {
      final deviceId = _tokenDocumentId(token);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .set(<String, Object?>{
        'token': token,
        'platform': 'android',
        'enabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _registeredUid = uid;
      _registeredToken = token;

      if (kDebugMode) {
        developer.log('FCM device token registered');
      }
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        developer.log(
          'FCM token registration failed: ${error.code}',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> unregisterCurrentDevice() async {
    final uid = _registeredUid ?? _auth.currentUser?.uid;
    final token = _registeredToken ?? await _messaging.getToken();
    if (uid == null || token == null || token.isEmpty) return;

    await _deleteDeviceToken(uid, token);
    _registeredUid = null;
    _registeredToken = null;
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
      if (kDebugMode) {
        developer.log(
          'FCM token removal failed: ${error.code}',
          error: error,
          stackTrace: stackTrace,
        );
      }
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
        ),
      ),
      payload: message.data['chatId'] as String?,
    );
  }

  String _tokenDocumentId(String token) =>
      base64Url.encode(utf8.encode(token)).replaceAll('=', '');
}
