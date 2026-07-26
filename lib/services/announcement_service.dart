import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/support_announcement.dart';
import '../utils/badge_formatters.dart';
import 'announcement_media_service.dart';

class AnnouncementService {
  AnnouncementService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static final DateTime _legacyDate = DateTime.fromMillisecondsSinceEpoch(0);

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('supportAnnouncements');

  DocumentReference<Map<String, dynamic>> _readStateRef(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('privateState')
          .doc('supportAnnouncements');

  DateTime effectiveCreatedAt(SupportAnnouncement item) => item.createdAt;

  String newAnnouncementId() => _announcements.doc().id;

  Stream<List<SupportAnnouncement>> watchActiveAnnouncements({int limit = 50}) {
    return _announcements
        .where('isActive', isEqualTo: true)
        .where('targetAudience', isEqualTo: 'allActiveUsers')
        .limit(limit)
        .snapshots()
        .handleError(_debugLogFirebaseException)
        .map((snapshot) {
          final now = DateTime.now();
          final items = snapshot.docs
              .map((doc) => SupportAnnouncement.fromMap(doc.id, doc.data()))
              .where(
                (item) =>
                    item.expiresAt == null || item.expiresAt!.isAfter(now),
              )
              .toList();
          items.sort(
            (a, b) => effectiveCreatedAt(b).compareTo(effectiveCreatedAt(a)),
          );
          return items;
        });
  }

  Stream<DateTime?> watchLastReadAt(String uid) {
    return _readStateRef(uid).snapshots().map((snapshot) {
      final value = snapshot.data()?['lastReadAt'];
      return value is Timestamp ? value.toDate() : null;
    });
  }

  bool isUnread(SupportAnnouncement item, DateTime? lastReadAt) {
    final createdAt = item.createdAt;
    return lastReadAt == null || createdAt.isAfter(lastReadAt);
  }

  void _debugLogFirebaseException(Object error) {
    if (!kDebugMode) return;
    if (error is FirebaseException) {
      debugPrint(
        'AnnouncementService FirebaseException: code=${error.code}, message=${error.message}',
      );
    } else {
      debugPrint('AnnouncementService error: $error');
    }
  }

  Stream<int> watchUnreadCount(String uid) {
    return watchLastReadAt(uid).asyncMap((lastReadAt) async {
      final snapshot = await _announcements
          .where('isActive', isEqualTo: true)
          .where('targetAudience', isEqualTo: 'allActiveUsers')
          .limit(100)
          .get()
          .catchError((Object error) {
            _debugLogFirebaseException(error);
            throw error;
          });

      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => SupportAnnouncement.fromMap(doc.id, doc.data()))
          .where(
            (item) => item.expiresAt == null || item.expiresAt!.isAfter(now),
          )
          .where((item) => isUnread(item, lastReadAt))
          .length;
    });
  }

  Future<void> markAllRead(String uid) async {
    await _readStateRef(uid).set({
      'lastReadAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createAnnouncement({
    required String announcementId,
    required String adminId,
    required String title,
    required String message,
    required String priority,
    required String announcementType,
    UploadedAnnouncementMedia? media,
    String? updateVersion,
    String? updateUrl,
    String? updateButtonLabel,
    bool isMandatoryUpdate = false,
  }) async {
    final safeTitle = title.trim();
    final safeMessage = message.trim();
    final safeVersion = updateVersion?.trim();
    final safeUrl = updateUrl?.trim();
    final safeButton = updateButtonLabel?.trim();

    if (safeTitle.isEmpty || safeTitle.length > 80) {
      throw ArgumentError('Enter a title between 1 and 80 characters.');
    }
    if (safeMessage.isEmpty || safeMessage.length > 1000) {
      throw ArgumentError('Enter a message between 1 and 1000 characters.');
    }
    if (!['normal', 'important', 'urgent'].contains(priority)) {
      throw ArgumentError('Select a valid priority.');
    }
    if (![
      'general',
      'new_feature',
      'app_update',
      'maintenance',
      'important',
    ].contains(announcementType)) {
      throw ArgumentError('Select a valid announcement type.');
    }
    if (announcementType == 'app_update' &&
        (safeUrl == null || safeUrl.isEmpty)) {
      throw ArgumentError('Enter the update URL for an app update.');
    }

    await _announcements.doc(announcementId).set({
      'title': safeTitle,
      'message': safeMessage,
      'priority': priority,
      'type': 'official_announcement',
      'announcementType': announcementType,
      'targetAudience': 'allActiveUsers',
      'isActive': true,
      'createdByAdminId': adminId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': null,
      'mediaType': media?.type,
      'mediaStoragePath': media?.storagePath,
      'mediaContentType': media?.contentType,
      'mediaSizeBytes': media?.sizeBytes,
      'mediaDurationMs': media?.durationMs,
      'mediaExpiresAt': media == null
          ? null
          : Timestamp.fromDate(
              DateTime.now().add(AnnouncementMediaService.cloudRetention),
            ),
      'mediaDeletedAt': null,
      'updateVersion': safeVersion?.isEmpty == true ? null : safeVersion,
      'updateUrl': safeUrl?.isEmpty == true ? null : safeUrl,
      'updateButtonLabel': safeButton?.isEmpty == true
          ? (announcementType == 'app_update' ? 'Update now' : null)
          : safeButton,
      'isMandatoryUpdate':
          announcementType == 'app_update' && isMandatoryUpdate,
    });
  }

  Future<void> expireAnnouncement(String announcementId) async {
    try {
      await _functions
          .httpsCallable('expireSupportAnnouncement')
          .call<void>(<String, dynamic>{'announcementId': announcementId});
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found' && error.code != 'unimplemented') rethrow;
      await _announcements.doc(announcementId).set({
        'isActive': false,
        'expiresAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  String formatBadge(int count) => BadgeFormatters.unread(count);
}
