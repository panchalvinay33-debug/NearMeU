import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  final bool isUnsent;
  final DateTime? unsentAt;

  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;

  final String type;
  final String? mediaUrl;

  final bool isSeen;
  final DateTime? seenAt;

  final List<String> deletedFor;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isUnsent = false,
    this.unsentAt,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.type = 'text',
    this.mediaUrl,
    this.isSeen = false,
    this.seenAt,
    this.deletedFor = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isUnsent': isUnsent,
      'unsentAt': unsentAt != null ? Timestamp.fromDate(unsentAt!) : null,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'type': type,
      'mediaUrl': mediaUrl,
      'isSeen': isSeen,
      'seenAt': seenAt != null ? Timestamp.fromDate(seenAt!) : null,
      'deletedFor': deletedFor,
    };
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isUnsent: map['isUnsent'] ?? false,
      unsentAt: map['unsentAt'] != null
          ? (map['unsentAt'] as Timestamp).toDate()
          : null,
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      replyToSenderId: map['replyToSenderId'],
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      isSeen: map['isSeen'] ?? false,
      seenAt: map['seenAt'] != null
          ? (map['seenAt'] as Timestamp).toDate()
          : null,
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
    );
  }

  bool canUnsend(String currentUserId) {
    if (isUnsent) return false;
    if (senderId != currentUserId) return false;

    final difference = DateTime.now().difference(timestamp);
    return difference.inMinutes <= 60;
  }

  bool get hasReply =>
      replyToMessageId != null &&
      replyToMessageId!.trim().isNotEmpty &&
      replyToText != null &&
      replyToText!.trim().isNotEmpty;

  bool get isImage =>
      type == 'image' && mediaUrl != null && mediaUrl!.isNotEmpty;

  bool isDeletedFor(String uid) {
    return deletedFor.contains(uid);
  }
}