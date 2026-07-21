import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/support_announcement.dart';
import '../services/announcement_service.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() => _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final _service = AnnouncementService();
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _priority = 'normal';
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null || _sending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send announcement?'),
        content: Text('${_title.text.trim()}\n\n${_message.text.trim()}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _sending = true);
    try {
      await _service.createAnnouncement(adminId: adminId, title: _title.text, message: _message.text, priority: _priority);
      _title.clear();
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement sent.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to send announcement. Check fields and admin access.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(title: const Text('Send NearMeU Announcement'), backgroundColor: Colors.black),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        TextField(controller: _title, maxLength: 80, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 12),
        TextField(controller: _message, maxLength: 1000, maxLines: 6, decoration: const InputDecoration(labelText: 'Message')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _priority,
          decoration: const InputDecoration(labelText: 'Priority'),
          items: const [
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'important', child: Text('Important')),
            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
          ],
          onChanged: _sending ? null : (value) => setState(() => _priority = value ?? 'normal'),
        ),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xff171717), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_title.text.trim().isEmpty ? 'Announcement title' : _title.text.trim()),
          const SizedBox(height: 6),
          Text(_message.text.trim().isEmpty ? 'Announcement message' : _message.text.trim(), style: const TextStyle(color: Colors.white70)),
        ])),
        const SizedBox(height: 18),
        ElevatedButton.icon(onPressed: _sending ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.campaign_rounded), label: const Text('Send to all active users')),
        const SizedBox(height: 24),
        const Text('Sent history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<List<SupportAnnouncement>>(
          stream: _service.watchActiveAnnouncements(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <SupportAnnouncement>[];
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (items.isEmpty) return const Text('No active announcements.');
            return Column(children: items.map((item) => Card(child: ListTile(title: Text(item.title), subtitle: Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: IconButton(icon: const Icon(Icons.hide_source), onPressed: () => _service.expireAnnouncement(item.id))))).toList());
          },
        ),
      ]),
    );
  }
}
