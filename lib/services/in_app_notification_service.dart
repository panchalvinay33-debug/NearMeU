import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

class InAppNotificationService {
  InAppNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  Stream<List<AppNotification>> watchNotifications(String uid, {int limit = 50}) {
    return _notifications(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppNotification.fromMap(doc.id, doc.data())).toList());
  }

  Stream<int> watchUnreadCount(String uid) {
    return _notifications(uid)
        .where('readAt', isNull: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markRead(String uid, String notificationId) async {
    await _notifications(uid).doc(notificationId).set({
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllRead(String uid) async {
    final snapshot = await _notifications(uid).where('readAt', isNull: true).limit(100).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {'readAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
