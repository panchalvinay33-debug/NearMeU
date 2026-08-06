import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/audio_call_model.dart';
import '../services/audio_call_service.dart';
import '../theme/app_colors.dart';

class AudioCallHistoryScreen extends StatefulWidget {
  const AudioCallHistoryScreen({super.key});

  @override
  State<AudioCallHistoryScreen> createState() => _AudioCallHistoryScreenState();
}

class _AudioCallHistoryScreenState extends State<AudioCallHistoryScreen> {
  final AudioCallService _calls = AudioCallService();
  late Future<List<AudioCallModel>> _history;

  @override
  void initState() {
    super.initState();
    _history = _calls.history();
  }

  Future<void> _refresh() async {
    setState(() => _history = _calls.history());
    await _history;
  }

  String _statusLabel(AudioCallModel call, String currentUid) {
    final outgoing = call.callerId == currentUid;
    switch (call.status) {
      case 'missed':
        return outgoing ? 'No answer' : 'Missed call';
      case 'rejected':
        return outgoing ? 'Declined' : 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      case 'ended':
        return outgoing ? 'Outgoing call' : 'Incoming call';
      default:
        return call.status;
    }
  }

  String _timeLabel(int? millis) {
    if (millis == null) return '';
    final value = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final clock = '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
    if (day == today) return 'Today, $clock';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $clock';
    }
    return '${value.day}/${value.month}/${value.year}, $clock';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Calls'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AudioCallModel>>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load call history.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              );
            }
            final calls = snapshot.data ?? const <AudioCallModel>[];
            if (calls.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.call_outlined, color: Colors.white38, size: 54),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'No calls yet',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: calls.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final call = calls[index];
                final outgoing = call.callerId == currentUid;
                final otherName = call.otherUserName(currentUid);
                final missed = call.status == 'missed' && !outgoing;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: Icon(
                      missed
                          ? Icons.call_missed_rounded
                          : outgoing
                              ? Icons.call_made_rounded
                              : Icons.call_received_rounded,
                      color: missed ? Colors.redAccent : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    otherName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${_statusLabel(call, currentUid)} • ${_timeLabel(call.createdAtMs)}',
                    style: TextStyle(
                      color: missed ? Colors.redAccent : Colors.white54,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.call_rounded,
                    color: AppColors.primary,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
