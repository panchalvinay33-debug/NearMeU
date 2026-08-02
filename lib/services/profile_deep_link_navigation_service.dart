import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/user_profile_screen.dart';
import 'profile_sharing_service.dart';

class ProfileDeepLinkNavigationService {
  ProfileDeepLinkNavigationService._();

  static final ProfileDeepLinkNavigationService instance =
      ProfileDeepLinkNavigationService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileSharingService _sharing = ProfileSharingService.instance;

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingLink;
  String? _lastOpenedPublicId;
  DateTime? _lastOpenedAt;
  bool _appShellReady = false;
  bool _opening = false;

  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    unawaited(_flushPendingLink());
  }

  void setAppShellReady(bool ready) {
    _appShellReady = ready;
    if (ready) unawaited(_flushPendingLink());
  }

  void queueLink(String? rawLink) {
    final link = rawLink?.trim();
    if (link == null || link.isEmpty) return;
    final publicId = _sharing.publicIdFromUri(link);
    if (publicId == null || publicId.isEmpty) return;
    _pendingLink = link;
    unawaited(_flushPendingLink());
  }

  Future<void> _flushPendingLink() async {
    if (!_appShellReady || _opening) return;

    final rawLink = _pendingLink;
    final currentUser = _auth.currentUser;
    final navigator = _navigatorKey?.currentState;
    if (rawLink == null || currentUser == null || navigator == null) return;

    final publicId = _sharing.publicIdFromUri(rawLink);
    if (publicId == null || publicId.isEmpty) {
      _pendingLink = null;
      return;
    }

    final now = DateTime.now();
    if (_lastOpenedPublicId == publicId &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
      _pendingLink = null;
      return;
    }

    _opening = true;
    _pendingLink = null;
    try {
      final profile = await _sharing.resolveSharedProfile(publicId);

      final currentNavigator = _navigatorKey?.currentState;
      final authenticatedUid = _auth.currentUser?.uid;
      if (!_appShellReady ||
          currentNavigator == null ||
          authenticatedUid != currentUser.uid) {
        if (authenticatedUid == currentUser.uid) _pendingLink = rawLink;
        return;
      }

      _lastOpenedPublicId = publicId;
      _lastOpenedAt = now;
      await currentNavigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UserProfileScreen(user: profile),
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Shared profile route failed',
        error: error,
        stackTrace: stackTrace,
      );
      final context = _navigatorKey?.currentContext;
      if (context != null && _appShellReady) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('This shared profile is unavailable.')),
        );
      }
    } finally {
      _opening = false;
      if (_pendingLink != null) unawaited(_flushPendingLink());
    }
  }
}
