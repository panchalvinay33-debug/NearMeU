import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reports =>
      _firestore.collection('reports');

  Future<bool> hasAlreadyReported({
    required String reporterId,
    required String reportedUserId,
  }) async {
    final snapshot = await _reports
        .where('reporterId', isEqualTo: reporterId)
        .where('reportedUserId', isEqualTo: reportedUserId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String description = '',
  }) async {
    final alreadyReported = await hasAlreadyReported(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
    );

    if (alreadyReported) {
      throw Exception(
        'You have already reported this user.',
      );
    }

    await _reports.add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
      'resolvedBy': null,
    });
  }

  Future<void> resolveReport(
    String reportId,
    String adminId,
  ) async {
    await _reports.doc(reportId).update({
      'status': 'resolved',
      'resolvedBy': adminId,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReport(
    String reportId,
  ) async {
    await _reports.doc(reportId).delete();
  }
}