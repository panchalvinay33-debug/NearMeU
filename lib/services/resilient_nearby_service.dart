import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'local_preview_cache.dart';

class NearbyLoadResult {
  const NearbyLoadResult({required this.users, required this.fromCache});

  final List<AppUser> users;
  final bool fromCache;
}

class ResilientNearbyService {
  ResilientNearbyService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    LocalPreviewCache? cache,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _auth = auth ?? FirebaseAuth.instance,
       _cache = cache ?? LocalPreviewCache();

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final LocalPreviewCache _cache;

  Future<NearbyLoadResult> loadCandidates() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const NearbyLoadResult(users: <AppUser>[], fromCache: false);
    }

    try {
      final result = await _functions
          .httpsCallable('getNearbyCandidates')
          .call<Map<String, dynamic>>();
      final users = _parseCandidates(result.data);
      await _cache.saveNearbyCandidates(uid, users);
      return NearbyLoadResult(
        users: List<AppUser>.unmodifiable(users),
        fromCache: false,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Nearby refresh failed; loading the last successful device snapshot',
        error: error,
        stackTrace: stackTrace,
      );
      final cached = await _cache.loadNearbyCandidates(uid);
      if (cached.isNotEmpty) {
        return NearbyLoadResult(
          users: List<AppUser>.unmodifiable(cached),
          fromCache: true,
        );
      }
      rethrow;
    }
  }

  List<AppUser> _parseCandidates(Map<String, dynamic> payload) {
    final rawUsers = payload['users'];
    if (rawUsers is! List) return const <AppUser>[];

    final users = <AppUser>[];
    for (final rawUser in rawUsers) {
      if (rawUser is! Map) continue;
      final data = Map<String, dynamic>.from(rawUser);
      final uid = data['uid'];
      if (uid is! String || uid.isEmpty) continue;

      final createdAtMillis = data.remove('createdAtMillis');
      final lastSeenMillis = data.remove('lastSeenMillis');
      data['createdAt'] = createdAtMillis is num
          ? Timestamp.fromMillisecondsSinceEpoch(createdAtMillis.toInt())
          : Timestamp.now();
      data['lastSeen'] = lastSeenMillis is num
          ? Timestamp.fromMillisecondsSinceEpoch(lastSeenMillis.toInt())
          : null;
      users.add(AppUser.fromMap(data, uid));
    }
    return users;
  }
}
