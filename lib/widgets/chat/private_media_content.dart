import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

import '../../models/message_model.dart';
import '../../services/private_media_service.dart';

class PrivateMediaContent extends StatefulWidget {
  const PrivateMediaContent({super.key, required this.message});

  final MessageModel message;

  @override
  State<PrivateMediaContent> createState() => _PrivateMediaContentState();
}

class _PrivateMediaContentState extends State<PrivateMediaContent> {
  final PrivateMediaService _mediaService = PrivateMediaService();

  String? _localPath;
  String? _thumbnailPath;
  String? _downloadError;
  bool _isDownloading = false;
  bool _isValidatingLocal = false;

  @override
  void initState() {
    super.initState();
    _localPath = widget.message.localMediaPath;
    _thumbnailPath = widget.message.localThumbnailPath;
    _validateLocalFiles();
  }

  @override
  void didUpdateWidget(covariant PrivateMediaContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _localPath = widget.message.localMediaPath;
      _thumbnailPath = widget.message.localThumbnailPath;
      _downloadError = null;
      _validateLocalFiles();
      return;
    }

    final nextLocalPath = widget.message.localMediaPath;
    if (nextLocalPath != null && nextLocalPath.trim().isNotEmpty) {
      _localPath = nextLocalPath;
      _downloadError = null;
    }
    final nextThumbnailPath = widget.message.localThumbnailPath;
    if (nextThumbnailPath != null && nextThumbnailPath.trim().isNotEmpty) {
      _thumbnailPath = nextThumbnailPath;
    }
    _validateLocalFiles();
  }

  Future<void> _validateLocalFiles() async {
    if (_isValidatingLocal) return;
    _isValidatingLocal = true;
    try {
      final path = _localPath;
      if (path != null) {
        final file = File(path);
        var valid = await file.exists();
        if (valid) {
          final bytes = await file.length();
          final declared = widget.message.mediaSizeBytes;
          valid = bytes > 0 && (declared == null || declared <= 0 || bytes == declared);
        }
        if (!valid) {
          try {
            if (await file.exists()) await file.delete();
          } catch (_) {}
          if (mounted) {
            setState(() {
              _localPath = null;
              _thumbnailPath = null;
            });
          } else {
            _localPath = null;
            _thumbnailPath = null;
          }
        }
      }

      final thumbnail = _thumbnailPath;
      if (thumbnail != null) {
        final file = File(thumbnail);
        final valid = await file.exists() && await file.length() > 0;
        if (!valid) {
          try {
            if (await file.exists()) await file.delete();
          } catch (_) {}
          if (mounted) {
            setState(() => _thumbnailPath = null);
          } else {
            _thumbnailPath = null;
          }
        }
      }
    } finally {
      _isValidatingLocal = false;
    }
  }

  Future<void> _download() async {
    final ownerUid = FirebaseAuth.instance.currentUser?.uid;
    if (ownerUid == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });
    try {
      final chatId = _mediaService.chatIdFor(
        widget.message.senderId,
        widget.message.receiverId,
      );
      final path = await _mediaService.downloadMessageMedia(
        ownerUid: ownerUid,
        chatId: chatId,
        message: widget.message,
      );
      final file = File(path);
      final bytes = await file.length();
      final declared = widget.message.mediaSizeBytes;
      if (bytes <= 0 || (declared != null && declared > 0 && bytes != declared)) {
        try {
          await file.delete();
        } catch (_) {}
        throw const PrivateMediaException(
          'The downloaded file did not pass verification. Please retry.',
        );
      }
      if (!mounted) return;
      setState(() {
        _localPath = path;
        _downloadError = null;
        if (widget.message.isVideo) {
          final expectedThumbnail = p.join(
            p.dirname(path),
            '${widget.message.id}_thumbnail.jpg',
          );
          if (File(expectedThumbnail).existsSync()) {
            _thumbnailPath = expectedThumbnail;
          }
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _downloadError = error.toString());
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _openLocalMedia() {
    final path = _localPath;
    if (path == null) return;
    if (widget.message.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PrivateVideoScreen(
            file: File(path),
            title: widget.message.text.trim().isEmpty
                ? 'Private video'
                : widget.message.text.trim(),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _PrivateImageScreen(file: File(path))),
    );
  }

  String _sizeLabel() {
    final bytes = widget.message.mediaSizeBytes;
    if (bytes == null || bytes <= 0) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }

  String _durationLabel() {
    final durationMs = widget.message.mediaDurationMs;
    if (durationMs == null || durationMs <= 0) return '';
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final localPath = _localPath;
    if (localPath != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openLocalMedia,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.message.isVideo
                ? _videoPreview(localPath)
                : Image.file(
                    File(localPath),
                    width: 260,
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _unavailableTile(),
                  ),
          ),
        ),
      );
    }

    if (!widget.message.hasRemoteMedia) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _unavailableTile(),
      );
    }

    final failed = _downloadError != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isDownloading ? null : _download,
        child: Container(
          width: 260,
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isDownloading)
                const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                )
              else
                Icon(
                  failed
                      ? Icons.refresh_rounded
                      : widget.message.isVideo
                      ? Icons.video_file_rounded
                      : Icons.image_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              const SizedBox(height: 10),
              Text(
                _isDownloading
                    ? 'Downloading securely...'
                    : failed
                    ? 'Retry download'
                    : widget.message.isVideo
                    ? 'Download private video'
                    : 'Download private photo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              if (failed)
                Text(
                  _downloadError!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                )
              else
                Text(
                  <String>[
                    _sizeLabel(),
                    if (widget.message.isVideo) _durationLabel(),
                  ].where((value) => value.isNotEmpty).join(' • '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoPreview(String localPath) {
    final thumbnailPath = _thumbnailPath;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (thumbnailPath != null && File(thumbnailPath).existsSync())
          Image.file(
            File(thumbnailPath),
            width: 260,
            height: 220,
            fit: BoxFit.cover,
          )
        else
          Container(
            width: 260,
            height: 220,
            color: Colors.black87,
            alignment: Alignment.center,
            child: const Icon(
              Icons.video_file_rounded,
              size: 48,
              color: Colors.white54,
            ),
          ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .62),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _durationLabel(),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unavailableTile() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white54),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Media is no longer available on this device or in the cloud.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateImageScreen extends StatelessWidget {
  const _PrivateImageScreen({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(
          minScale: .8,
          maxScale: 5,
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _PrivateVideoScreen extends StatefulWidget {
  const _PrivateVideoScreen({required this.file, required this.title});

  final File file;
  final String title;

  @override
  State<_PrivateVideoScreen> createState() => _PrivateVideoScreenState();
}

class _PrivateVideoScreenState extends State<_PrivateVideoScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _initialization = _controller.initialize().then((_) {
      _controller.setLooping(false);
      if (mounted) setState(() {});
    });
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not play this video.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final aspectRatio = _controller.value.aspectRatio > 0
              ? _controller.value.aspectRatio
              : 16 / 9;
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                IconButton.filled(
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
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
