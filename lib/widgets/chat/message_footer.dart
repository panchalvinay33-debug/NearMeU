import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class MessageFooter extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String time;

  const MessageFooter({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMe || message.isUnsent) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          time,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            message.isSeen ? Icons.done_all : Icons.done,
            size: 15,
            color: message.isSeen
                ? Colors.lightBlueAccent
                : Colors.white54,
          ),
        ],
      ),
    );
  }
}