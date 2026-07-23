import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class QuotedReply extends StatelessWidget {
  final MessageModel message;
  final bool repliedToMe;
  final String otherUserName;

  const QuotedReply({
    super.key,
    required this.message,
    required this.repliedToMe,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    if (!message.hasReply) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .20),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: const Color(0xFF8B5CF6), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            repliedToMe ? "You" : otherUserName,
            style: const TextStyle(
              color: const Color(0xFF8B5CF6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            message.replyToText ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
