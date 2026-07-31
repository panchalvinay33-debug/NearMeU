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
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      );
    }

    final icon = message.isSeen || message.isDelivered
        ? Icons.done_all
        : Icons.done;
    final color = message.isSeen ? Colors.lightBlueAccent : Colors.white54;
    final semantics = message.isSeen
        ? 'Read'
        : message.isDelivered
        ? 'Delivered'
        : 'Sent';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(width: 6),
          Semantics(
            label: semantics,
            child: Icon(icon, size: 15, color: color),
          ),
        ],
      ),
    );
  }
}
