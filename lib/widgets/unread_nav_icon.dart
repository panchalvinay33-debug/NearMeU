import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../utils/badge_formatters.dart';
import '../theme/app_colors.dart';

class UnreadNavIcon extends StatelessWidget {
  const UnreadNavIcon({
    super.key,
    required this.userId,
    required this.icon,
  });

  final String userId;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return Icon(icon);

    return StreamBuilder<int>(
      stream: ChatService().watchPrivateUnreadCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            if (count > 0)
              Positioned(
                right: -10,
                top: -8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: Text(
                    BadgeFormatters.unread(count),
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
      },
    );
  }
}
