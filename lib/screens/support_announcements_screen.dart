import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/support_announcement.dart';
import '../services/announcement_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatters.dart';
import '../widgets/chat/linkified_message_text.dart';

class SupportAnnouncementsScreen extends StatefulWidget {
  const SupportAnnouncementsScreen({super.key});

  @override
  State<SupportAnnouncementsScreen> createState() =>
      _SupportAnnouncementsScreenState();
}

class _SupportAnnouncementsScreenState
    extends State<SupportAnnouncementsScreen> {
  final AnnouncementService _service = AnnouncementService();
  late Stream<List<SupportAnnouncement>> _announcementsStream;
  bool _markingRead = false;
  DateTime? _optimisticLastReadAt;

  @override
  void initState() {
    super.initState();
    _announcementsStream = _service.watchActiveAnnouncements();
  }

  DateTime? _effectiveLastReadAt(DateTime? serverValue) {
    final optimistic = _optimisticLastReadAt;
    if (optimistic == null) return serverValue;
    if (serverValue == null || optimistic.isAfter(serverValue)) return optimistic;
    return serverValue;
  }

  Future<void> _markRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _markingRead) return;

    setState(() => _markingRead = true);
    try {
      await _service.markAllRead(uid);
      if (!mounted) return;
      setState(() => _optimisticLastReadAt = DateTime.now());
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('All support announcements marked read.')),
        );
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Mark support announcements read failed: code=${error.code}, message=${error.message}',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not mark announcements read. Please check your connection.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  void _retryAnnouncements() {
    setState(() {
      _announcementsStream = _service.watchActiveAnnouncements();
    });
  }

  void _logAnnouncementError(Object error) {
    if (!kDebugMode) return;
    if (error is FirebaseException) {
      debugPrint(
        'Support announcements stream failed: code=${error.code}, message=${error.message}',
      );
      return;
    }
    debugPrint('Support announcements stream failed: $error');
  }

  Color _priorityColor(String priority) => switch (priority) {
        'urgent' => Colors.redAccent,
        'important' => Colors.orangeAccent,
        _ => AppColors.primaryLight,
      };

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NearMeU Support'),
        backgroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: uid == null || _markingRead ? null : _markRead,
            icon: _markingRead
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all_rounded),
            label: const Text('Mark all read'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<SupportAnnouncement>>(
        stream: _announcementsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _logAnnouncementError(snapshot.error!);
            return _AnnouncementErrorState(onRetry: _retryAnnouncements);
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Official NearMeU announcements will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (uid == null) {
            return _AnnouncementList(
              items: items,
              lastReadAt: null,
              service: _service,
              priorityColor: _priorityColor,
              onRefresh: _markRead,
            );
          }

          return StreamBuilder<DateTime?>(
            stream: _service.watchLastReadAt(uid),
            builder: (context, readSnapshot) {
              final lastReadAt = _effectiveLastReadAt(readSnapshot.data);
              final sorted = List<SupportAnnouncement>.from(items)
                ..sort((a, b) {
                  final aUnread = _service.isUnread(a, lastReadAt);
                  final bUnread = _service.isUnread(b, lastReadAt);
                  if (aUnread != bUnread) return aUnread ? -1 : 1;
                  return b.createdAt.compareTo(a.createdAt);
                });

              return _AnnouncementList(
                items: sorted,
                lastReadAt: lastReadAt,
                service: _service,
                priorityColor: _priorityColor,
                onRefresh: _markRead,
              );
            },
          );
        },
      ),
    );
  }
}

class _AnnouncementList extends StatelessWidget {
  const _AnnouncementList({
    required this.items,
    required this.lastReadAt,
    required this.service,
    required this.priorityColor,
    required this.onRefresh,
  });

  final List<SupportAnnouncement> items;
  final DateTime? lastReadAt;
  final AnnouncementService service;
  final Color Function(String priority) priorityColor;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final color = priorityColor(item.priority);
          final unread = service.isUnread(item, lastReadAt);

          return Semantics(
            label: unread ? 'Unread support announcement' : 'Read support announcement',
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: unread
                    ? AppColors.primary.withValues(alpha: .10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: unread
                      ? AppColors.primaryLight
                      : color.withValues(alpha: .45),
                  width: unread ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_rounded, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: unread ? AppColors.primary : Colors.white10,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          unread ? 'Unread' : 'Read',
                          style: TextStyle(
                            color: unread ? Colors.white : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinkifiedMessageText(
                    text: item.message,
                    baseStyle: const TextStyle(
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    DateFormatters.chatPreview(item.createdAt),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementErrorState extends StatelessWidget {
  const _AnnouncementErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryLight,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'We couldn’t load support announcements.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again. NearMeU support updates will appear here when available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
