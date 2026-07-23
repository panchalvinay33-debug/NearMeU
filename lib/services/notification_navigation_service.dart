import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/chat_screen.dart';
import '../security/notification_route.dart';
import 'user_service.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingChatId;
  String? _lastOpenedChatId;
  DateTime? _lastOpenedAt;
  bool _appShellReady = false;
  bool _opening = false;

  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    unawaited(_flushPendingRoute());
  }

  void setAppShellReady(bool ready) {
    _appShellReady = ready;
    if (ready) unawaited(_flushPendingRoute());
  }

  void queueChatId(String? value) {
    final chatId = NotificationRoute.normalizedChatId(value);
    if (chatId == null) return;
    _pendingChatId = chatId;
    unawaited(_flushPendingRoute());
  }

  Future<void> _flushPendingRoute() async {
    if (!_appShellReady || _opening) return;

    final chatId = _pendingChatId;
    final currentUser = _auth.currentUser;
    final navigator = _navigatorKey?.currentState;
    if (chatId == null || currentUser == null || navigator == null) return;

    _opening = true;
    _pendingChatId = null;
    try {
      final chat = await _firestore.collection('chats').doc(chatId).get();
      final participants = chat.data()?['participants'];
      final otherUserId = NotificationRoute.otherParticipant(
        currentUid: currentUser.uid,
        participants: participants,
      );
      if (!chat.exists || otherUserId == null) return;

      final otherUser = await _userService.getUser(otherUserId);
      if (otherUser == null || otherUser.isSuspended) return;

      final blocked = await _userService.isBlockedEitherWay(
        currentUserId: currentUser.uid,
        otherUserId: otherUserId,
      );
      if (blocked) return;

      final currentNavigator = _navigatorKey?.currentState;
      if (!_appShellReady || currentNavigator == null) {
        _pendingChatId = chatId;
        return;
      }

      final now = DateTime.now();
      if (_lastOpenedChatId == chatId &&
          _lastOpenedAt != null &&
          now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
        return;
      }
      _lastOpenedChatId = chatId;
      _lastOpenedAt = now;

      unawaited(
        currentNavigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(
              otherUserId: otherUserId,
              otherUserName: otherUser.nickname.trim().isEmpty
                  ? 'NearMeU User'
                  : otherUser.nickname.trim(),
            ),
          ),
        ),
      );
    } on FirebaseException catch (error, stackTrace) {
      if (_isTransient(error.code)) _pendingChatId = chatId;
      developer.log(
        'Notification chat route failed: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Notification chat route failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _opening = false;
    }
  }

  bool _isTransient(String code) {
    return code == 'aborted' ||
        code == 'deadline-exceeded' ||
        code == 'resource-exhausted' ||
        code == 'unavailable';
  }
}
