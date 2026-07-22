import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_announcement.dart';
import '../utils/badge_formatters.dart';

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('supportAnnouncements');

  DocumentReference<Map<String, dynamic>> _readStateRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('privateState').doc('supportAnnouncements');

  Stream<List<SupportAnnouncement>> watchActiveAnnouncements({int limit = 50}) {
    return _announcements
        .where('isActive', isEqualTo: true)
        .where('targetAudience', isEqualTo: 'allActiveUsers')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportAnnouncement.fromMap(doc.id, doc.data()))
            .where((item) => item.expiresAt == null || item.expiresAt!.isAfter(DateTime.now()))
            .toList());
  }

  Stream<int> watchUnreadCount(String uid) {
    return _readStateRef(uid).snapshots().asyncMap((readDoc) async {
      final lastReadAt = readDoc.data()?['lastReadAt'];
      Query<Map<String, dynamic>> query = _announcements
          .where('isActive', isEqualTo: true)
          .where('targetAudience', isEqualTo: 'allActiveUsers');
      if (lastReadAt is Timestamp) {
        query = query.where('createdAt', isGreaterThan: lastReadAt);
      }
      final snapshot = await query.limit(100).get();
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => SupportAnnouncement.fromMap(doc.id, doc.data()))
          .where((item) => item.expiresAt == null || item.expiresAt!.isAfter(now))
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
