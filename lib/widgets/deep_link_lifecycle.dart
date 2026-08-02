import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/profile_deep_link_navigation_service.dart';
import '../services/profile_sharing_service.dart';

class DeepLinkLifecycle extends StatefulWidget {
  const DeepLinkLifecycle({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<DeepLinkLifecycle> createState() => _DeepLinkLifecycleState();
}

class _DeepLinkLifecycleState extends State<DeepLinkLifecycle> {
  final ProfileSharingService _sharing = ProfileSharingService.instance;
  final ProfileDeepLinkNavigationService _navigation =
      ProfileDeepLinkNavigationService.instance;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _navigation.attachNavigatorKey(widget.navigatorKey);
    _sharing.setNativeDeepLinkHandler((link) async {
      _navigation.queueLink(link);
    });
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) _navigation.setAppShellReady(false);
    });
    unawaited(_consumeInitialLink());
  }

  Future<void> _consumeInitialLink() async {
    final link = await _sharing.getInitialNativeLink();
    _navigation.queueLink(link);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
