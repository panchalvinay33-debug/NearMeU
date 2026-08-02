import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/chat_screen.dart';
import '../screens/support_announcements_screen.dart';
import '../security/notification_route.dart';
import 'profile_deep_link_navigation_service.dart';
import 'user_service.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  GlobalKey<NavigatorState>? _navigatorKey;
  NotificationDestination? _pendingDestination;
  String? _lastOpenedKey;
  DateTime? _lastOpenedAt;
  bool _appShellReady = false;
  bool _opening = false;

  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    unawaited(_flushPendingRoute());
  }

  void setAppShellReady(bool ready) {
    _appShellReady = ready;
    ProfileDeepLinkNavigationService.instance.setAppShellReady(ready);
    if (ready) unawaited(_flushPendingRoute());
  }

  void queueChatId(String? value) {
    final chatId = NotificationRoute.normalizedChatId(value);
    if (chatId == null) return;
    queueDestination(NotificationDestination.privateChat(chatId));
  }

  void queueRemoteData(Map<String, dynamic> data) {
    final destination = NotificationRoute.fromData(data);
    if (destination != null) queueDestination(destination);
  }

  void queuePayload(String? payload) {
    final destination = NotificationRoute.fromPayload(payload);
    if (destination != null) queueDestination(destination);
  }

  void queueDestination(NotificationDestination destination) {
    _pendingDestination = destination;
    unawaited(_flushPendingRoute());
  }

  Future<void> _flushPendingRoute() async {
    if (!_appShellReady || _opening) return;
    final destination = _pendingDestination;
    final currentUser = _auth.currentUser;
    final navigator = _navigatorKey?.currentState;
    if (destination == null || currentUser == null || navigator == null) return;

    _opening = true;
    _pendingDestination = null;
    try {
      final key = destination.payload;
      final now = DateTime.now();
      if (_lastOpenedKey == key &&
          _lastOpenedAt != null &&
          now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
        return;
      }

      if (destination.isSupportAnnouncement) {
        _lastOpenedKey = key;
        _lastOpenedAt = now;
        await navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const SupportAnnouncementsScreen(),
          ),
        );
        return;
      }

      final chatId = destination.value;
      if (chatId == null) return;
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
      final authenticatedUid = _auth.currentUser?.uid;
      if (!_appShellReady ||
          currentNavigator == null ||
          authenticatedUid != currentUser.uid) {
        if (authenticatedUid == currentUser.uid) {
          _pendingDestination = destination;
        }
        return;
      }

      _lastOpenedKey = key;
      _lastOpenedAt = now;
      await currentNavigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            otherUserId: otherUserId,
            otherUserName: otherUser.nickname.trim().isEmpty
                ? 'NearMeU User'
                : otherUser.nickname.trim(),
          ),
        ),
      );
    } on FirebaseException catch (error, stackTrace) {
      if (_isTransient(error.code)) _pendingDestination = destination;
      developer.log(
        'Notification route failed: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Notification route failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _opening = false;
      if (_pendingDestination != null) unawaited(_flushPendingRoute());
    }
  }

  bool _isTransient(String code) {
    return code == 'aborted' ||
        code == 'deadline-exceeded' ||
        code == 'resource-exhausted' ||
        code == 'unavailable';
  }
}
