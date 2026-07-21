import 'package:cloud_firestore/cloud_firestore.dart';

class SupportAnnouncement {
  const SupportAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.createdAt,
    required this.isActive,
    this.createdByAdminId,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String message;
  final String priority;
  final DateTime? createdAt;
  final bool isActive;
  final String? createdByAdminId;
  final DateTime? expiresAt;

  factory SupportAnnouncement.fromMap(String id, Map<String, dynamic> data) {
    return SupportAnnouncement(
      id: id,
      title: (data['title'] as String?) ?? 'NearMeU Announcement',
      message: (data['message'] as String?) ?? '',
      priority: (data['priority'] as String?) ?? 'normal',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] != false,
      createdByAdminId: data['createdByAdminId'] as String?,
      expiresAt: data['expiresAt'] is Timestamp
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }
}
