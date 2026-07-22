import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/support_announcement.dart';
import '../utils/badge_formatters.dart';

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('supportAnnouncements');

  DocumentReference<Map<String, dynamic>> _readStateRef(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('privateState')
          .doc('supportAnnouncements');

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
          .where((item) => item.expiresAt == null || item.expiresAt!.isAfter(now))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    return lastReadAt == null || item.createdAt.isAfter(lastReadAt);
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
          .where((item) => item.expiresAt == null || item.expiresAt!.isAfter(now))
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
    required String adminId,
    required String title,
    required String message,
    required String priority,
  }) async {
    final safeTitle = title.trim();
    final safeMessage = message.trim();
    if (safeTitle.isEmpty || safeTitle.length > 80) {
      throw ArgumentError('Enter a title between 1 and 80 characters.');
    }
    if (safeMessage.isEmpty || safeMessage.length > 1000) {
      throw ArgumentError('Enter a message between 1 and 1000 characters.');
    }
    if (!['normal', 'important', 'urgent'].contains(priority)) {
      throw ArgumentError('Select a valid priority.');
    }
    await _announcements.add({
      'title': safeTitle,
      'message': safeMessage,
      'priority': priority,
      'type': 'official_announcement',
      'targetAudience': 'allActiveUsers',
      'isActive': true,
      'createdByAdminId': adminId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': null,
    });
  }

  Future<void> expireAnnouncement(String announcementId) async {
    await _announcements.doc(announcementId).set({
      'isActive': false,
      'expiresAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String formatBadge(int count) => BadgeFormatters.unread(count);
}
