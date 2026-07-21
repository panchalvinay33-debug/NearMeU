import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/in_app_notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatters.dart';
import 'chat_screen.dart';
import 'support_announcements_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final InAppNotificationService _service = InAppNotificationService();

  Future<void> _refresh() async => Future<void>.delayed(const Duration(milliseconds: 350));

  Future<void> _open(AppNotification notification, String uid) async {
    await _service.markRead(uid, notification.id);
    if (!mounted) return;
    if (notification.type == 'private_message' && notification.relatedUserId != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: notification.relatedUserId!, otherUserName: 'Chat')));
      return;
    }
    if (notification.type == 'official_announcement' || notification.relatedAnnouncementId != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportAnnouncementsScreen()));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No additional action is available.')));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('User not logged in')));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.black,
        actions: [TextButton(onPressed: () => _service.markAllRead(uid), child: const Text('Mark all read'))],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _service.watchNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: ElevatedButton(onPressed: _refresh, child: const Text('Retry')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('No notifications yet.', style: TextStyle(color: Colors.white70)));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  onTap: () => _open(item, uid),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: item.isRead ? AppColors.cardBorder : AppColors.primary.withValues(alpha: .6))),
                  tileColor: item.isRead ? AppColors.surface : const Color(0xFF1E1630),
                  leading: Icon(item.isRead ? Icons.notifications_none : Icons.notifications_active, color: AppColors.primaryLight),
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.body.isEmpty ? 'Open for details' : item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(DateFormatters.chatPreview(item.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
