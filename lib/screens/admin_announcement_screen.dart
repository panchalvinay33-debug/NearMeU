import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/support_announcement.dart';
import '../services/announcement_media_service.dart';
import '../services/announcement_service.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() =>
      _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final AnnouncementService _service = AnnouncementService();
  final AnnouncementMediaService _mediaService = AnnouncementMediaService();
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _version = TextEditingController();
  final TextEditingController _updateUrl = TextEditingController();
  final TextEditingController _buttonLabel = TextEditingController();

  String _priority = 'normal';
  String _announcementType = 'general';
  bool _mandatoryUpdate = false;
  bool _sending = false;
  bool _preparingMedia = false;
  bool _recording = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordingPath;
  Timer? _recordingTimer;
  AnnouncementMediaUpload? _selectedMedia;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_recording) unawaited(_recorder.cancel());
    unawaited(_recorder.dispose());
    _title.dispose();
    _message.dispose();
    _version.dispose();
    _updateUrl.dispose();
    _buttonLabel.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_sending || _preparingMedia || _recording) return;
    setState(() => _preparingMedia = true);
    try {
      final media = await _mediaService.pickImage();
      if (media != null && mounted) {
        await _replaceSelectedMedia(media);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _preparingMedia = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_sending || _preparingMedia || _recording) return;
    setState(() => _preparingMedia = true);
    try {
      final media = await _mediaService.pickVideo();
      if (media != null && mounted) {
        await _replaceSelectedMedia(media);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _preparingMedia = false);
    }
  }

  Future<void> _replaceSelectedMedia(AnnouncementMediaUpload media) async {
    final previous = _selectedMedia;
    _selectedMedia = media;
    if (mounted) setState(() {});
    if (previous != null && previous.file.path != media.file.path) {
      try {
        if (await previous.file.exists()) await previous.file.delete();
      } catch (_) {}
    }
  }

  Future<void> _removeSelectedMedia() async {
    final media = _selectedMedia;
    setState(() => _selectedMedia = null);
    if (media != null) {
      try {
        if (await media.file.exists()) await media.file.delete();
      } catch (_) {}
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_recording) {
      await _stopVoiceRecording();
    } else {
      await _startVoiceRecording();
    }
  }

  Future<void> _startVoiceRecording() async {
    if (_sending || _preparingMedia || _recording) return;
    if (!await _recorder.hasPermission()) {
      _showError('Microphone permission is required.');
      return;
    }
    final temporary = await getTemporaryDirectory();
    final path = p.join(
      temporary.path,
      'nearmeu_announcement_voice_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordingDuration = Duration.zero;
        _recordingPath = path;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_recording) return;
        final next = _recordingDuration + const Duration(seconds: 1);
        setState(() => _recordingDuration = next);
        if (next >= AnnouncementMediaService.maximumVoiceDuration) {
          unawaited(_stopVoiceRecording());
        }
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (!_recording) return;
    _recordingTimer?.cancel();
    final measured = _recordingDuration;
    final expectedPath = _recordingPath;
    setState(() {
      _recording = false;
      _preparingMedia = true;
    });
    try {
      final stoppedPath = await _recorder.stop();
      final path = stoppedPath ?? expectedPath;
      if (path == null) throw StateError('Could not finish voice recording.');
      final media = await _mediaService.prepareVoice(
        file: File(path),
        durationMs: measured.inMilliseconds,
      );
      await _replaceSelectedMedia(media);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _preparingMedia = false;
          _recordingDuration = Duration.zero;
          _recordingPath = null;
        });
      }
    }
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_recording) return;
    _recordingTimer?.cancel();
    try {
      await _recorder.cancel();
    } catch (_) {}
    final path = _recordingPath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _recording = false;
        _recordingDuration = Duration.zero;
        _recordingPath = null;
      });
    }
  }

  String _durationLabel(Duration duration) {
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inMinutes}:$seconds';
  }

  String _mediaLabel(AnnouncementMediaUpload media) => switch (media.type) {
        'video' => 'Video • ${_durationLabel(Duration(milliseconds: media.durationMs ?? 0))}',
        'voice' => 'Voice • ${_durationLabel(Duration(milliseconds: media.durationMs ?? 0))}',
        _ => 'Photo',
      };

  Future<void> _send() async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null || _sending || _recording) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send announcement?'),
        content: Text(
          '${_title.text.trim()}\n\n${_message.text.trim()}\n\n'
          '${_selectedMedia == null ? 'Text only' : _mediaLabel(_selectedMedia!)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);
    final announcementId = _service.newAnnouncementId();
    UploadedAnnouncementMedia? uploaded;
    try {
      final media = _selectedMedia;
      if (media != null) {
        uploaded = await _mediaService.upload(
          adminId: adminId,
          announcementId: announcementId,
          media: media,
        );
      }
      await _service.createAnnouncement(
        announcementId: announcementId,
        adminId: adminId,
        title: _title.text,
        message: _message.text,
        priority: _priority,
        announcementType: _announcementType,
        media: uploaded,
        updateVersion: _version.text,
        updateUrl: _updateUrl.text,
        updateButtonLabel: _buttonLabel.text,
        isMandatoryUpdate: _mandatoryUpdate,
      );
      final sentMedia = _selectedMedia;
      _title.clear();
      _message.clear();
      _version.clear();
      _updateUrl.clear();
      _buttonLabel.clear();
      setState(() {
        _priority = 'normal';
        _announcementType = 'general';
        _mandatoryUpdate = false;
        _selectedMedia = null;
      });
      if (sentMedia != null) {
        try {
          if (await sentMedia.file.exists()) await sentMedia.file.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement sent. Media remains available for 7 days.'),
        ),
      );
    } catch (error) {
      if (uploaded != null) {
        await _mediaService.deleteUploadedMedia(uploaded.storagePath);
      }
      if (kDebugMode) {
        if (error is FirebaseException) {
          debugPrint(
            'Admin announcement write failed: code=${error.code}, message=${error.message}',
          );
        } else {
          debugPrint('Admin announcement write failed: $error');
        }
      }
      _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final media = _selectedMedia;
    final isUpdate = _announcementType == 'app_update';

    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(
        title: const Text('Send NearMeU Announcement'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _title,
            maxLength: 80,
            enabled: !_sending,
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLength: 1000,
            maxLines: 6,
            enabled: !_sending,
            decoration: const InputDecoration(labelText: 'Message'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _announcementType,
            decoration: const InputDecoration(labelText: 'Announcement type'),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('General')),
              DropdownMenuItem(value: 'new_feature', child: Text('New feature')),
              DropdownMenuItem(value: 'app_update', child: Text('App update')),
              DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
              DropdownMenuItem(value: 'important', child: Text('Important')),
            ],
            onChanged: _sending
                ? null
                : (value) => setState(() {
                    _announcementType = value ?? 'general';
                    if (_announcementType != 'app_update') {
                      _mandatoryUpdate = false;
                    }
                  }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'important', child: Text('Important')),
              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
            ],
            onChanged: _sending
                ? null
                : (value) => setState(() => _priority = value ?? 'normal'),
          ),
          if (isUpdate) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _version,
              enabled: !_sending,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Version, e.g. 1.2.0'),
            ),
            TextField(
              controller: _updateUrl,
              enabled: !_sending,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Play Store or APK update URL',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _buttonLabel,
              enabled: !_sending,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Button label (default: Update now)',
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mandatory update'),
              subtitle: const Text(
                'Marks this update as required in the announcement card.',
              ),
              value: _mandatoryUpdate,
              onChanged: _sending
                  ? null
                  : (value) => setState(() => _mandatoryUpdate = value),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Attachment (optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (media == null && !_recording)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _sending || _preparingMedia ? null : _pickPhoto,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Photo'),
                ),
                OutlinedButton.icon(
                  onPressed: _sending || _preparingMedia ? null : _pickVideo,
                  icon: const Icon(Icons.video_library_rounded),
                  label: const Text('Video'),
                ),
                OutlinedButton.icon(
                  onPressed: _sending || _preparingMedia
                      ? null
                      : _toggleVoiceRecording,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Record voice'),
                ),
              ],
            ),
          if (_preparingMedia)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
          if (_recording)
            Card(
              child: ListTile(
                leading: const Icon(Icons.mic_rounded, color: Colors.redAccent),
                title: Text('Recording ${_durationLabel(_recordingDuration)}'),
                subtitle: const Text('Maximum 2 minutes'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      onPressed: _cancelVoiceRecording,
                      icon: const Icon(Icons.delete_rounded),
                    ),
                    IconButton.filled(
                      onPressed: _stopVoiceRecording,
                      icon: const Icon(Icons.stop_rounded),
                    ),
                  ],
                ),
              ),
            ),
          if (media != null)
            Card(
              child: ListTile(
                leading: Icon(
                  media.type == 'image'
                      ? Icons.image_rounded
                      : media.type == 'video'
                          ? Icons.video_file_rounded
                          : Icons.graphic_eq_rounded,
                ),
                title: Text(_mediaLabel(media)),
                subtitle: const Text('Cloud copy automatically expires in 7 days.'),
                trailing: IconButton(
                  onPressed: _sending ? null : _removeSelectedMedia,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff171717),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _title.text.trim().isEmpty
                      ? 'Announcement title'
                      : _title.text.trim(),
                ),
                const SizedBox(height: 6),
                Text(
                  _message.text.trim().isEmpty
                      ? 'Announcement message'
                      : _message.text.trim(),
                  style: const TextStyle(color: Colors.white70),
                ),
                if (media != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _mediaLabel(media),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _sending || _recording || _preparingMedia ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.campaign_rounded),
            label: Text(_sending ? 'Uploading and publishing...' : 'Send to all active users'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sent history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SupportAnnouncement>>(
            stream: _service.watchActiveAnnouncements(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <SupportAnnouncement>[];
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) return const Text('No active announcements.');
              return Column(
                children: items
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: Icon(
                            item.hasMedia
                                ? Icons.perm_media_rounded
                                : Icons.campaign_rounded,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Expire announcement and delete media',
                            icon: const Icon(Icons.hide_source),
                            onPressed: () => _service.expireAnnouncement(item.id),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
