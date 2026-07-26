import 'package:flutter/material.dart';

class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmojiPicker;
  final bool isSendingMedia;
  final bool isRecordingVoice;
  final Duration recordingDuration;
  final VoidCallback onEmojiTap;
  final VoidCallback? onAttachment;
  final VoidCallback? onSend;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onCancelVoice;
  final VoidCallback onTextFieldTap;
  final Widget? replyPreview;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showEmojiPicker,
    required this.onEmojiTap,
    required this.onSend,
    required this.onTextFieldTap,
    this.isSendingMedia = false,
    this.isRecordingVoice = false,
    this.recordingDuration = Duration.zero,
    this.onAttachment,
    this.onVoiceTap,
    this.onCancelVoice,
    this.replyPreview,
  });

  String _durationLabel() {
    final minutes = recordingDuration.inMinutes;
    final seconds = recordingDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (replyPreview != null) replyPreview!,
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(color: Color(0xff0B0B0B)),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isRecordingVoice ? onCancelVoice : onEmojiTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isRecordingVoice
                        ? Colors.red.withValues(alpha: .18)
                        : const Color(0xff171717),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isRecordingVoice
                        ? Icons.delete_outline_rounded
                        : showEmojiPicker
                        ? Icons.keyboard_rounded
                        : Icons.emoji_emotions_outlined,
                    color: isRecordingVoice ? Colors.redAccent : Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: isRecordingVoice ? 54 : null,
                  decoration: BoxDecoration(
                    color: const Color(0xff171717),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: isRecordingVoice
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const _RecordingPulse(),
                              const SizedBox(width: 10),
                              Text(
                                _durationLabel(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Tap send to finish',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: !isSendingMedia,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          cursorColor: const Color(0xFF8B5CF6),
                          minLines: 1,
                          maxLines: 5,
                          onTap: onTextFieldTap,
                          decoration: InputDecoration(
                            hintText: isSendingMedia
                                ? 'Preparing media...'
                                : 'Type a message...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              18,
                              14,
                              4,
                              14,
                            ),
                            suffixIcon: isSendingMedia
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Color(0xFFB56BFF),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Record voice message',
                                        onPressed: onVoiceTap,
                                        icon: Icon(
                                          Icons.mic_none_rounded,
                                          color: onVoiceTap == null
                                              ? Colors.white24
                                              : Colors.white70,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Attach photo or video',
                                        onPressed: onAttachment,
                                        icon: Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: onAttachment == null
                                              ? Colors.white24
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: isSendingMedia
                    ? null
                    : isRecordingVoice
                    ? onVoiceTap
                    : onSend,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          (isRecordingVoice ? onVoiceTap : onSend) == null ||
                              isSendingMedia
                          ? const <Color>[
                              Color(0xff4A4A4A),
                              Color(0xff333333),
                            ]
                          : const <Color>[
                              Color(0xff9C27B0),
                              Color(0xff673AB7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: .35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecordingVoice
                        ? Icons.send_rounded
                        : Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordingPulse extends StatefulWidget {
  const _RecordingPulse();

  @override
  State<_RecordingPulse> createState() => _RecordingPulseState();
}

class _RecordingPulseState extends State<_RecordingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: .35,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.fiber_manual_record, color: Colors.redAccent),
    );
  }
}
