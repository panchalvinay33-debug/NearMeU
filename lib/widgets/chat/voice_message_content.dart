import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/message_model.dart';
import '../../services/voice_message_service.dart';

class VoiceMessageContent extends StatefulWidget {
  const VoiceMessageContent({super.key, required this.message});

  final MessageModel message;

  @override
  State<VoiceMessageContent> createState() => _VoiceMessageContentState();
}

class _VoiceMessageContentState extends State<VoiceMessageContent> {
  final AudioPlayer _player = AudioPlayer();
  final VoiceMessageService _voiceService = VoiceMessageService();

  String? _localPath;
  bool _isDownloading = false;
  bool _isPreparing = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _localPath = widget.message.localMediaPath;
    _discardMissingFile();
  }

  @override
  void didUpdateWidget(covariant VoiceMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _player.stop();
      _isLoaded = false;
      _localPath = widget.message.localMediaPath;
      _discardMissingFile();
    } else if (widget.message.localMediaPath?.isNotEmpty == true) {
      final nextPath = widget.message.localMediaPath;
      if (nextPath != _localPath) _isLoaded = false;
      _localPath = nextPath;
      _discardMissingFile();
    }
  }

  void _discardMissingFile() {
    final path = _localPath;
    if (path != null && !File(path).existsSync()) {
      _localPath = null;
      _isLoaded = false;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<String?> _ensureLocalFile() async {
    final path = _localPath;
    if (path != null && File(path).existsSync()) return path;

    final ownerUid = FirebaseAuth.instance.currentUser?.uid;
    if (ownerUid == null || _isDownloading) return null;
    setState(() => _isDownloading = true);
    try {
      final chatId = _voiceService.chatIdFor(
        widget.message.senderId,
        widget.message.receiverId,
      );
      final downloaded = await _voiceService.downloadVoice(
        ownerUid: ownerUid,
        chatId: chatId,
        message: widget.message,
      );
      if (!mounted) return downloaded;
      setState(() {
        _localPath = downloaded;
        _isLoaded = false;
      });
      return downloaded;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPreparing || _isDownloading) return;
    if (_player.playing) {
      await _player.pause();
      return;
    }

    setState(() => _isPreparing = true);
    try {
      final path = await _ensureLocalFile();
      if (path == null) return;
      if (!_isLoaded) {
        await _player.setFilePath(path);
        _isLoaded = true;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    } catch (error) {
      _isLoaded = false;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  String _format(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final declaredDuration = Duration(
      milliseconds: widget.message.mediaDurationMs ?? 0,
    );

    return Container(
      width: 250,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing == true;
              return IconButton.filled(
                onPressed: _isDownloading || _isPreparing
                    ? null
                    : _togglePlayback,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .16),
                ),
                icon: _isDownloading || _isPreparing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : _localPath == null
                            ? Icons.download_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'Voice message',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration =
                            durationSnapshot.data ?? declaredDuration;
                        final maximum = duration.inMilliseconds > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0;
                        final current = position.inMilliseconds
                            .clamp(0, maximum.toInt())
                            .toDouble();
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: current,
                                max: maximum,
                                onChanged: !_isLoaded
                                    ? null
                                    : (value) => _player.seek(
                                        Duration(milliseconds: value.round()),
                                      ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _format(position),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  _format(duration),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
