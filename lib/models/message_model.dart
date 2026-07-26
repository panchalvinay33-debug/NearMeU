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
  final String? mediaStoragePath;
  final String? mediaContentType;
  final int? mediaSizeBytes;
  final int? mediaDurationMs;
  final Map<String, DateTime> downloadAcknowledgements;
  final DateTime? cloudExpiresAt;
  final DateTime? cloudMediaDeletedAt;

  // Device-only fields. They are persisted in the encrypted SQLCipher store
  // and are deliberately excluded from Firestore serialization.
  final String? localMediaPath;
  final String? localThumbnailPath;

  final bool isSeen;
  final DateTime? seenAt;
  final List<String> deletedFor;

  const MessageModel({
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
    this.mediaStoragePath,
    this.mediaContentType,
    this.mediaSizeBytes,
    this.mediaDurationMs,
    this.downloadAcknowledgements = const <String, DateTime>{},
    this.cloudExpiresAt,
    this.cloudMediaDeletedAt,
    this.localMediaPath,
    this.localThumbnailPath,
    this.isSeen = false,
    this.seenAt,
    this.deletedFor = const <String>[],
  });

  static DateTime? _dateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  static Map<String, DateTime> _acknowledgements(dynamic value) {
    if (value is! Map) return const <String, DateTime>{};
    final result = <String, DateTime>{};
    for (final entry in value.entries) {
      final uid = entry.key;
      final acknowledgedAt = _dateTime(entry.value);
      if (uid is String && uid.isNotEmpty && acknowledgedAt != null) {
        result[uid] = acknowledgedAt;
      }
    }
    return Map<String, DateTime>.unmodifiable(result);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
      'mediaStoragePath': mediaStoragePath,
      'mediaContentType': mediaContentType,
      'mediaSizeBytes': mediaSizeBytes,
      'mediaDurationMs': mediaDurationMs,
      'downloadAcknowledgements': downloadAcknowledgements.map(
        (uid, time) => MapEntry(uid, Timestamp.fromDate(time)),
      ),
      'cloudExpiresAt': cloudExpiresAt != null
          ? Timestamp.fromDate(cloudExpiresAt!)
          : null,
      'cloudMediaDeletedAt': cloudMediaDeletedAt != null
          ? Timestamp.fromDate(cloudMediaDeletedAt!)
          : null,
      'isSeen': isSeen,
      'seenAt': seenAt != null ? Timestamp.fromDate(seenAt!) : null,
      'deletedFor': deletedFor,
    };
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] is String ? map['senderId'] as String : '',
      receiverId: map['receiverId'] is String
          ? map['receiverId'] as String
          : '',
      text: map['text'] is String ? map['text'] as String : '',
      timestamp: _dateTime(map['timestamp']) ?? DateTime.now(),
      isUnsent: map['isUnsent'] == true,
      unsentAt: _dateTime(map['unsentAt']),
      replyToMessageId: map['replyToMessageId'] is String
          ? map['replyToMessageId'] as String
          : null,
      replyToText: map['replyToText'] is String
          ? map['replyToText'] as String
          : null,
      replyToSenderId: map['replyToSenderId'] is String
          ? map['replyToSenderId'] as String
          : null,
      type: map['type'] is String ? map['type'] as String : 'text',
      mediaUrl: map['mediaUrl'] is String ? map['mediaUrl'] as String : null,
      mediaStoragePath: map['mediaStoragePath'] is String
          ? map['mediaStoragePath'] as String
          : null,
      mediaContentType: map['mediaContentType'] is String
          ? map['mediaContentType'] as String
          : null,
      mediaSizeBytes: map['mediaSizeBytes'] is num
          ? (map['mediaSizeBytes'] as num).toInt()
          : null,
      mediaDurationMs: map['mediaDurationMs'] is num
          ? (map['mediaDurationMs'] as num).toInt()
          : null,
      downloadAcknowledgements: _acknowledgements(
        map['downloadAcknowledgements'],
      ),
      cloudExpiresAt: _dateTime(map['cloudExpiresAt']),
      cloudMediaDeletedAt: _dateTime(map['cloudMediaDeletedAt']),
      localMediaPath: map['localMediaPath'] is String
          ? map['localMediaPath'] as String
          : null,
      localThumbnailPath: map['localThumbnailPath'] is String
          ? map['localThumbnailPath'] as String
          : null,
      isSeen: map['isSeen'] == true,
      seenAt: _dateTime(map['seenAt']),
      deletedFor: List<String>.from(map['deletedFor'] ?? const <String>[]),
    );
  }

  MessageModel withLocalMedia({
    String? localMediaPath,
    String? localThumbnailPath,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
      isUnsent: isUnsent,
      unsentAt: unsentAt,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      type: type,
      mediaUrl: mediaUrl,
      mediaStoragePath: mediaStoragePath,
      mediaContentType: mediaContentType,
      mediaSizeBytes: mediaSizeBytes,
      mediaDurationMs: mediaDurationMs,
      downloadAcknowledgements: downloadAcknowledgements,
      cloudExpiresAt: cloudExpiresAt,
      cloudMediaDeletedAt: cloudMediaDeletedAt,
      localMediaPath: localMediaPath ?? this.localMediaPath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      isSeen: isSeen,
      seenAt: seenAt,
      deletedFor: deletedFor,
    );
  }

  bool canUnsend(String currentUserId) {
    if (isUnsent || senderId != currentUserId) return false;
    return DateTime.now().difference(timestamp).inMinutes <= 60;
  }

  bool get hasReply =>
      replyToMessageId != null &&
      replyToMessageId!.trim().isNotEmpty &&
      replyToText != null &&
      replyToText!.trim().isNotEmpty;

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isVoice => type == 'voice';
  bool get isMedia => isImage || isVideo || isVoice;
  bool get hasLocalMedia =>
      localMediaPath != null && localMediaPath!.trim().isNotEmpty;
  bool get hasRemoteMedia =>
      cloudMediaDeletedAt == null &&
      ((mediaStoragePath != null && mediaStoragePath!.trim().isNotEmpty) ||
          (mediaUrl != null && mediaUrl!.trim().isNotEmpty));

  bool isDownloadedBy(String uid) => downloadAcknowledgements.containsKey(uid);
  bool isDeletedFor(String uid) => deletedFor.contains(uid);
}
