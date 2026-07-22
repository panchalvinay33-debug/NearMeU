import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../theme/app_colors.dart';

class ChatTabBadge extends StatelessWidget {
  const ChatTabBadge({
    super.key,
    required this.userId,
    this.icon = Icons.chat_bubble_outline,
  });

  final String userId;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
                top: -7,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: const Color(0xFF1A1A1A),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
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
