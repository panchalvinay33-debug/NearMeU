import 'package:flutter/material.dart';

class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmojiPicker;
  final VoidCallback onEmojiTap;
  final VoidCallback? onSend;
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
    this.replyPreview,
  });

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
                onTap: onEmojiTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xff171717),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    showEmojiPicker
                        ? Icons.keyboard_rounded
                        : Icons.emoji_emotions_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff171717),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: const Color(0xFF8B5CF6),
                    minLines: 1,
                    maxLines: 5,
                    onTap: onTextFieldTap,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onSend,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: onSend == null
                          ? const [Color(0xff4A4A4A), Color(0xff333333)]
                          : const [Color(0xff9C27B0), Color(0xff673AB7)],
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
