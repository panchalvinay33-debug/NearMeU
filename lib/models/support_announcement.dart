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
    this.announcementType = 'general',
    this.mediaType,
    this.mediaStoragePath,
    this.mediaContentType,
    this.mediaSizeBytes,
    this.mediaDurationMs,
    this.mediaExpiresAt,
    this.mediaDeletedAt,
    this.updateVersion,
    this.updateUrl,
    this.updateButtonLabel,
    this.isMandatoryUpdate = false,
  });

  final String id;
  final String title;
  final String message;
  final String priority;
  final DateTime createdAt;
  final bool isActive;
  final String? createdByAdminId;
  final DateTime? expiresAt;
  final String announcementType;
  final String? mediaType;
  final String? mediaStoragePath;
  final String? mediaContentType;
  final int? mediaSizeBytes;
  final int? mediaDurationMs;
  final DateTime? mediaExpiresAt;
  final DateTime? mediaDeletedAt;
  final String? updateVersion;
  final String? updateUrl;
  final String? updateButtonLabel;
  final bool isMandatoryUpdate;

  bool get hasMedia =>
      mediaType != null &&
      mediaStoragePath != null &&
      mediaStoragePath!.trim().isNotEmpty &&
      mediaDeletedAt == null;

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
  bool get isVoice => mediaType == 'voice';
  bool get isUpdate => announcementType == 'app_update';

  bool get isMediaExpired {
    final expiry = mediaExpiresAt;
    return mediaDeletedAt != null ||
        (expiry != null && !expiry.isAfter(DateTime.now()));
  }

  factory SupportAnnouncement.fromMap(String id, Map<String, dynamic> data) {
    DateTime? date(dynamic value) =>
        value is Timestamp ? value.toDate() : null;

    return SupportAnnouncement(
      id: id,
      title: (data['title'] as String?) ?? 'NearMeU Announcement',
      message: (data['message'] as String?) ?? '',
      priority: (data['priority'] as String?) ?? 'normal',
      createdAt: date(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      isActive: data['isActive'] != false,
      createdByAdminId: data['createdByAdminId'] as String?,
      expiresAt: date(data['expiresAt']),
      announcementType: (data['announcementType'] as String?) ?? 'general',
      mediaType: data['mediaType'] as String?,
      mediaStoragePath: data['mediaStoragePath'] as String?,
      mediaContentType: data['mediaContentType'] as String?,
      mediaSizeBytes: (data['mediaSizeBytes'] as num?)?.toInt(),
      mediaDurationMs: (data['mediaDurationMs'] as num?)?.toInt(),
      mediaExpiresAt: date(data['mediaExpiresAt']),
      mediaDeletedAt: date(data['mediaDeletedAt']),
      updateVersion: data['updateVersion'] as String?,
      updateUrl: data['updateUrl'] as String?,
      updateButtonLabel: data['updateButtonLabel'] as String?,
      isMandatoryUpdate: data['isMandatoryUpdate'] == true,
    );
  }
}
