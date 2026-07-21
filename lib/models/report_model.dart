import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String description;
  final String status;
  final DateTime? createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    required this.status,
    this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory ReportModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ReportModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'],
      reviewedAt:
          (map['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
    };
  }
}