import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../models/support_announcement.dart';
import '../services/announcement_media_service.dart';

class AnnouncementMediaContent extends StatefulWidget {
  const AnnouncementMediaContent({
    super.key,
    required this.announcement,
  });

  final SupportAnnouncement announcement;

  @override
  State<AnnouncementMediaContent> createState() =>
      _AnnouncementMediaContentState();
}

class _AnnouncementMediaContentState extends State<AnnouncementMediaContent> {
  final AnnouncementMediaService _service = AnnouncementMediaService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _localPath;
  bool _loading = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> _ensureLocal() async {
    if (_localPath != null && File(_localPath!).existsSync()) return _localPath;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _loading) return null;
    setState(() => _loading = true);
    try {
      final path = await _service.ensureLocalCopy(
        ownerUid: uid,
        announcement: widget.announcement,
      );
      if (mounted) setState(() => _localPath = path);
      return path;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open() async {
    final path = await _ensureLocal();
    if (path == null || !mounted) return;
    if (widget.announcement.isVoice) {
      if (_audioPlayer.audioSource == null) {
        await _audioPlayer.setFilePath(path);
      }
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }
    if (widget.announcement.isVideo) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _AnnouncementVideoScreen(file: File(path)),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AnnouncementImageScreen(file: File(path)),
      ),
    );
  }

  String _durationLabel() {
    final milliseconds = widget.announcement.mediaDurationMs ?? 0;
    final duration = Duration(milliseconds: milliseconds);
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcement.isMediaExpired) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.white38),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This announcement media expired after 7 days.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      );
    }
    if (!widget.announcement.hasMedia) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: _loading ? null : _open,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              if (_loading)
                const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing == true;
                    return Icon(
                      widget.announcement.isVoice
                          ? playing
                              ? Icons.pause_circle_rounded
                              : Icons.play_circle_rounded
                          : widget.announcement.isVideo
                              ? Icons.play_circle_fill_rounded
                              : Icons.image_rounded,
                      size: 38,
                      color: Colors.white,
                    );
                  },
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.announcement.isVoice
                          ? 'Play voice update'
                          : widget.announcement.isVideo
                              ? 'Watch update video'
                              : 'View update photo',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.announcement.mediaDurationMs != null)
                      Text(
                        _durationLabel(),
                        style: const TextStyle(color: Colors.white54),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.download_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementImageScreen extends StatelessWidget {
  const _AnnouncementImageScreen({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(child: Image.file(file, fit: BoxFit.contain)),
      ),
    );
  }
}

class _AnnouncementVideoScreen extends StatefulWidget {
  const _AnnouncementVideoScreen({required this.file});

  final File file;

  @override
  State<_AnnouncementVideoScreen> createState() =>
      _AnnouncementVideoScreenState();
}

class _AnnouncementVideoScreenState extends State<_AnnouncementVideoScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _initialization = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not play this video.'));
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio > 0
                      ? _controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(_controller),
                ),
                IconButton.filled(
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  iconSize: 42,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
