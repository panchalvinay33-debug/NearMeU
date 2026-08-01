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

  DateTime? _timestampDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
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

    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(_chatId);
    final messageRef = chatRef.collection('messages').doc(message.id);
    final receiverRef = firestore.collection('users').doc(message.receiverId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: messageRef.snapshots(includeMetadataChanges: true),
      builder: (context, messageSnapshot) {
        final messageData = messageSnapshot.data?.data();
        final remoteRead = messageData?['isSeen'] == true;
        final remoteDelivered = messageData?['isDelivered'] == true;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: chatRef.snapshots(includeMetadataChanges: true),
          builder: (context, chatSnapshot) {
            final chatData = chatSnapshot.data?.data();
            final readStates = chatData?['readStates'];
            final receiverReadState = readStates is Map
                ? readStates[message.receiverId]
                : null;
            final lastReadAt = receiverReadState is Map
                ? _timestampDate(receiverReadState['lastReadAt'])
                : null;
            final readFromChatState =
                lastReadAt != null && !lastReadAt.isBefore(message.timestamp);
            final read = remoteRead || readFromChatState || fallbackRead;

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: receiverRef.snapshots(includeMetadataChanges: true),
              builder: (context, receiverSnapshot) {
                final receiverData = receiverSnapshot.data?.data();
                final receiverLastSeen = _timestampDate(
                  receiverData?['lastSeen'] ?? receiverData?['lastSeenAt'],
                );
                final receiverActiveAfterSend =
                    receiverData?['isOnline'] == true ||
                    (receiverLastSeen != null &&
                        !receiverLastSeen.isBefore(message.timestamp));
                final delivered =
                    remoteDelivered ||
                    read ||
                    receiverActiveAfterSend ||
                    fallbackDelivered;
                return _footer(delivered: delivered, read: read);
              },
            );
          },
        );
      },
    );
  }
}
