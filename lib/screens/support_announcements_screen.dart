import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/support_announcement.dart';
import '../services/announcement_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatters.dart';

class SupportAnnouncementsScreen extends StatefulWidget {
  const SupportAnnouncementsScreen({super.key});

  @override
  State<SupportAnnouncementsScreen> createState() => _SupportAnnouncementsScreenState();
}

class _SupportAnnouncementsScreenState extends State<SupportAnnouncementsScreen> {
  final AnnouncementService _service = AnnouncementService();
  late Stream<List<SupportAnnouncement>> _announcementsStream;

  @override
  void initState() {
    super.initState();
    _announcementsStream = _service.watchActiveAnnouncements();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _service.markAllRead(uid);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcements will be marked read when connection returns.')),
      );
    }
  }

  void _retryAnnouncements() {
    setState(() {
      _announcementsStream = _service.watchActiveAnnouncements();
    });
  }

  void _logAnnouncementError(Object error) {
    if (error is FirebaseException) {
      debugPrint(
        'Support announcements stream failed: ${error.code} ${error.message ?? ''}',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NearMeU Support'),
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: _markRead, icon: const Icon(Icons.done_all_rounded))],
      ),
      body: StreamBuilder<List<SupportAnnouncement>>(
        stream: _announcementsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _logAnnouncementError(snapshot.error!);
            return _AnnouncementErrorState(error: snapshot.error!, onRetry: _retryAnnouncements);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Official NearMeU announcements will appear here.', textAlign: TextAlign.center),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _markRead,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final color = _priorityColor(item.priority);
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withValues(alpha: .45)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.verified_rounded, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 8),
                    Text(item.message, style: const TextStyle(color: Colors.white70, height: 1.35)),
                    const SizedBox(height: 12),
                    Text(DateFormatters.chatPreview(item.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementErrorState extends StatelessWidget {
  const _AnnouncementErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  bool get _isPermissionDenied => error is FirebaseException && (error as FirebaseException).code == 'permission-denied';
  bool get _isNetwork => error is FirebaseException && ['unavailable', 'deadline-exceeded', 'cancelled'].contains((error as FirebaseException).code);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPermissionDenied ? Icons.lock_outline_rounded : (_isNetwork ? Icons.wifi_off_rounded : Icons.support_agent_rounded),
              color: AppColors.primaryLight,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _isPermissionDenied ? 'Announcements are not available for this account.' : (_isNetwork ? 'You appear to be offline.' : 'We couldn’t load support announcements.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _isPermissionDenied ? 'Active NearMeU accounts can read support announcements. Contact support if this seems wrong.' : (_isNetwork ? 'Please check your connection and try again.' : 'Something unexpected happened. Please try again shortly.'),
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
