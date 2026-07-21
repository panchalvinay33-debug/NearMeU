import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.relatedChatId,
    this.relatedUserId,
    this.relatedAnnouncementId,
    this.actionType,
    this.actionData,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String? relatedChatId;
  final String? relatedUserId;
  final String? relatedAnnouncementId;
  final String? actionType;
  final Map<String, dynamic>? actionData;

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      type: (data['type'] as String?) ?? 'general',
      title: (data['title'] as String?) ?? 'NearMeU',
      body: (data['body'] as String?) ?? (data['preview'] as String?) ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      readAt: data['readAt'] is Timestamp
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      relatedChatId: data['relatedChatId'] as String?,
      relatedUserId: data['relatedUserId'] as String?,
      relatedAnnouncementId: data['relatedAnnouncementId'] as String?,
      actionType: data['actionType'] as String?,
      actionData: data['actionData'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['actionData'] as Map)
          : null,
    );
  }
}
