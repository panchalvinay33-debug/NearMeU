import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Supplies a bounded broad discovery pool when the local location cell does
/// not contain enough eligible people. Exact coordinates are never queried or
/// exposed; only the existing public user documents are read.
class DiscoveryService {
  DiscoveryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppUser>> watchDiscoveryPool({int limit = 100}) {
    final boundedLimit = limit.clamp(25, 150).toInt();
    return _firestore
        .collection('users')
        .limit(boundedLimit)
        .snapshots(includeMetadataChanges: false)
        .map(
          (snapshot) => snapshot.docs
              .map((document) => AppUser.fromMap(document.data(), document.id))
              .toList(growable: false),
        );
  }
}
