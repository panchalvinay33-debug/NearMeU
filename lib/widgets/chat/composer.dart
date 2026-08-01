import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/premium_entitlement_service.dart';

class ChatComposer extends StatefulWidget {
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

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final PremiumEntitlementService _premiumService = PremiumEntitlementService();
  bool _isPremium = false;
  bool _checkingPremium = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshPremium());
  }

  String _durationLabel() {
    final minutes = widget.recordingDuration.inMinutes;
    final seconds = widget.recordingDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _refreshPremium({bool forceRefresh = false}) async {
    if (_checkingPremium) return;
    _checkingPremium = true;
    try {
      final entitlement = await _premiumService.getCurrent(
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() => _isPremium = entitlement.isPremium);
    } catch (_) {
      if (mounted) setState(() => _isPremium = false);
    } finally {
      _checkingPremium = false;
    }
  }

  Future<void> _runPremiumAction({
    required VoidCallback? action,
    required String feature,
  }) async {
    if (action == null || _checkingPremium) return;
    _checkingPremium = true;
    try {
      final entitlement = await _premiumService.getCurrent(forceRefresh: true);
      if (!mounted) return;
      setState(() => _isPremium = entitlement.isPremium);
      if (entitlement.isPremium) {
        action();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Premium is required to $feature.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PremiumEntitlementException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      _checkingPremium = false;
    }
  }

  Widget _premiumIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? action,
    required String feature,
  }) {
    final enabled = action != null;
    return IconButton(
      tooltip: _isPremium ? tooltip : '$tooltip · Premium',
      onPressed: !enabled
          ? null
          : () => unawaited(
              _runPremiumAction(action: action, feature: feature),
            ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: !enabled
                ? Colors.white24
                : _isPremium
                ? Colors.white70
                : const Color(0xFFB56BFF),
          ),
          if (!_isPremium)
            const Positioned(
              right: -5,
              bottom: -5,
              child: Icon(
                Icons.lock_rounded,
                size: 12,
                color: Color(0xFFE4B8FF),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.replyPreview != null) widget.replyPreview!,
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(color: Color(0xff0B0B0B)),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.isRecordingVoice
                    ? widget.onCancelVoice
                    : widget.onEmojiTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isRecordingVoice
                        ? Colors.red.withValues(alpha: .18)
                        : const Color(0xff171717),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.isRecordingVoice
                        ? Icons.delete_outline_rounded
                        : widget.showEmojiPicker
                        ? Icons.keyboard_rounded
                        : Icons.emoji_emotions_outlined,
                    color: widget.isRecordingVoice
                        ? Colors.redAccent
                        : Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: widget.isRecordingVoice ? 54 : null,
                  decoration: BoxDecoration(
                    color: const Color(0xff171717),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: widget.isRecordingVoice
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
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          enabled: !widget.isSendingMedia,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          cursorColor: const Color(0xFF8B5CF6),
                          minLines: 1,
                          maxLines: 5,
                          onTap: widget.onTextFieldTap,
                          decoration: InputDecoration(
                            hintText: widget.isSendingMedia
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
                            suffixIcon: widget.isSendingMedia
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
                                      _premiumIconButton(
                                        tooltip: 'Record voice message',
                                        icon: Icons.mic_none_rounded,
                                        action: widget.onVoiceTap,
                                        feature: 'send voice messages',
                                      ),
                                      _premiumIconButton(
                                        tooltip: 'Attach photo or video',
                                        icon: Icons.add_circle_outline_rounded,
                                        action: widget.onAttachment,
                                        feature: 'send photos or videos',
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
                onTap: widget.isSendingMedia
                    ? null
                    : widget.isRecordingVoice
                    ? widget.onVoiceTap
                    : widget.onSend,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          (widget.isRecordingVoice
                                      ? widget.onVoiceTap
                                      : widget.onSend) ==
                                  null ||
                              widget.isSendingMedia
                          ? const <Color>[Color(0xff4A4A4A), Color(0xff333333)]
                          : const <Color>[Color(0xff9C27B0), Color(0xff673AB7)],
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
                  child: const Icon(
                    Icons.send_rounded,
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
