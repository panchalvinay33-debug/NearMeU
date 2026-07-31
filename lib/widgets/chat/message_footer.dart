import 'package:cloud_firestore/cloud_firestore.dart';
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

  String get _chatId {
    final participants = <String>[message.senderId, message.receiverId]..sort();
    return participants.join('_');
  }

  Widget _footer({required bool delivered, required bool read}) {
    final icon = delivered || read ? Icons.done_all : Icons.done;
    final color = read ? Colors.lightBlueAccent : Colors.white54;
    final semantics = read ? 'Read' : delivered ? 'Delivered' : 'Sent';

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

    final fallbackRead = message.isSeen;
    final fallbackDelivered = message.isDelivered || fallbackRead;

    if (message.id.trim().isEmpty ||
        message.senderId.trim().isEmpty ||
        message.receiverId.trim().isEmpty) {
      return _footer(delivered: fallbackDelivered, read: fallbackRead);
    }

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .doc(message.id);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: messageRef.snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final read = data?['isSeen'] == true || fallbackRead;
        final delivered =
            data?['isDelivered'] == true || read || fallbackDelivered;
        return _footer(delivered: delivered, read: read);
      },
    );
  }
}
