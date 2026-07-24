import 'dart:async';

import 'package:flutter/material.dart';

import '../services/trusted_read_service.dart';
import '../theme/app_colors.dart';
import '../utils/badge_formatters.dart';

class UnreadNavIcon extends StatefulWidget {
  const UnreadNavIcon({
    super.key,
    required this.userId,
    required this.icon,
  });

  final String userId;
  final IconData icon;

  @override
  State<UnreadNavIcon> createState() => _UnreadNavIconState();
}

class _UnreadNavIconState extends State<UnreadNavIcon> {
  final TrustedReadService _trustedReadService = TrustedReadService();
  Timer? _timer;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_refresh()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (widget.userId.isEmpty) return;
    try {
      final chats = await _trustedReadService.getChatPreviews();
      final nextCount = chats.fold<int>(
        0,
        (total, chat) => total + chat.unreadCount,
      );
      if (mounted && nextCount != _count) {
        setState(() => _count = nextCount);
      }
    } catch (_) {
      // Keep the last known badge during a temporary backend outage.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(widget.icon),
        if (_count > 0)
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFF1A1A1A),
                  width: 2,
                ),
              ),
              child: Text(
                BadgeFormatters.unread(_count),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
