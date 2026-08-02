import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/user_profile_screen.dart';
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
  StreamSubscription<User?>? _authSubscription;
  String? _pendingLink;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _sharing.setNativeDeepLinkHandler(_handleLink);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && _pendingLink != null) {
        final link = _pendingLink!;
        _pendingLink = null;
        unawaited(_handleLink(link));
      }
    });
    unawaited(_consumeInitialLink());
  }

  Future<void> _consumeInitialLink() async {
    final link = await _sharing.getInitialNativeLink();
    if (link != null && link.trim().isNotEmpty) {
      await _handleLink(link);
    }
  }

  Future<void> _handleLink(String rawLink) async {
    final publicId = _sharing.publicIdFromUri(rawLink);
    if (publicId == null || publicId.isEmpty || _opening) return;

    if (FirebaseAuth.instance.currentUser == null) {
      _pendingLink = rawLink;
      return;
    }

    _opening = true;
    try {
      final user = await _sharing.resolveSharedProfile(publicId);
      final navigator = widget.navigatorKey.currentState;
      if (navigator == null || !mounted) return;
      await navigator.push(
        MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
      );
    } catch (_) {
      final context = widget.navigatorKey.currentContext;
      if (context != null && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('This shared profile is unavailable.')),
        );
      }
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
