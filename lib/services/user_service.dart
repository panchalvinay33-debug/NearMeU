import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../security/suspension_service.dart';
import '../utils/nearby_user_presenter.dart';
import 'validation_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SuspensionService _suspensionService = SuspensionService();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection('publicProfiles');

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _firestore.collection('blocks');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  Future<void> createUser(AppUser user) async {
    ValidationService.age(user.age ?? 0);
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<void> saveUser(AppUser user) async {
    ValidationService.age(user.age ?? 0);
    await _users.doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Returns the private profile. Firestore rules restrict this to the owner
  /// and administrators.
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  /// Returns the privacy-safe profile used by Nearby, chat headers, and reports.
  Future<AppUser?> getPublicUser(String uid) async {
    final doc = await _publicProfiles.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromPublicMap(doc.data()!, doc.id);
  }

  Stream<AppUser?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<DateTime?> watchLastSeen(String uid) {
    return _publicProfiles.doc(uid).snapshots().map((doc) {
      final value = doc.data()?['lastSeen'];
      return value is Timestamp ? value.toDate() : null;
    });
  }

  String? getCurrentUserId() => FirebaseAuth.instance.currentUser?.uid;

  bool isProfileComplete(AppUser user) {
    return user.nickname.trim().isNotEmpty &&
        user.gender.trim().isNotEmpty &&
        user.lookingFor.trim().isNotEmpty &&
        user.isAdult;
  }

  String normalizeGender(String value) {
    switch (value.trim().toLowerCase()) {
      case 'male':
      case 'man':
      case 'men':
        return 'Male';
      case 'female':
      case 'woman':
      case 'women':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return '';
    }
  }

  String normalizeLookingFor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'male':
      case 'man':
      case 'men':
        return 'Male';
      case 'female':
      case 'woman':
      case 'women':
        return 'Female';
      case 'both':
        return 'Both';
      default:
        return '';
    }
  }

  Future<void> updateNickname(String uid, String nickname) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _users.doc(uid).update(<String, Object>{
      'nickname': ValidationService.nickname(nickname),
    });
  }

  Future<void> updateAge(String uid, int age) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _users.doc(uid).update(<String, Object>{
      'age': ValidationService.age(age),
    });
  }

  Future<void> updateGender(String uid, String gender) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _users.doc(uid).update(<String, Object>{
      'gender': ValidationService.profileChoice(gender, 'gender'),
    });
  }

  Future<void> updateLookingFor(String uid, String lookingFor) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _users.doc(uid).update(<String, Object>{
      'lookingFor': ValidationService.profileChoice(
        normalizeLookingFor(lookingFor),
        'preference',
      ),
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    required String nickname,
    required int age,
    required String gender,
    required String lookingFor,
  }) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _users.doc(uid).set(<String, Object>{
      'nickname': ValidationService.nickname(nickname),
      'age': ValidationService.age(age),
      'gender': ValidationService.profileChoice(
        normalizeGender(gender),
        'gender',
      ),
      'lookingFor': ValidationService.profileChoice(
        normalizeLookingFor(lookingFor),
        'preference',
      ),
    }, SetOptions(merge: true));
  }

  Future<void> updateLocation({
    required String uid,
    required double latitude,
    required double longitude,
    String? city,
    String? state,
    String? country,
  }) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _users.doc(uid).set(<String, Object?>{
      'latitude': ValidationService.latitude(latitude),
      'longitude': ValidationService.longitude(longitude),
      'city': city,
      'state': state,
      'country': country,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserLocation(String uid) async {
    await _suspensionService.ensureUserAllowed(uid);

    if (!await Geolocator.isLocationServiceEnabled()) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    String? city;
    String? state;
    String? country;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final locality = placemark.locality?.trim();
        final district = placemark.subAdministrativeArea?.trim();
        city = locality?.isNotEmpty == true
            ? locality
            : (district?.isNotEmpty == true ? district : null);
        state = placemark.administrativeArea;
        country = placemark.country;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Reverse geocoding failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await updateLocation(
      uid: uid,
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      state: state,
      country: country,
    );
  }

  Future<void> updateLastSeen(String uid) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _users.doc(uid).set(<String, Object>{
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    await _users.doc(uid).set(<String, Object>{
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateMessageNotifications({
    required String uid,
    required bool enabled,
  }) async {
    await _users.doc(uid).set(<String, Object>{
      'messageNotificationsEnabled': enabled,
    }, SetOptions(merge: true));
  }

  Future<void> updateNearbyAlerts({
    required String uid,
    required bool enabled,
  }) async {
    await _users.doc(uid).set(<String, Object>{
      'nearbyAlertsEnabled': enabled,
    }, SetOptions(merge: true));
  }

  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _suspensionService.ensureUserAllowed(currentUserId);
    if (currentUserId == targetUserId) {
      throw ArgumentError('You cannot block yourself.');
    }

    final batch = _firestore.batch();
    batch.set(
      _users.doc(currentUserId),
      <String, Object>{
        'blockedUsers': FieldValue.arrayUnion(<String>[targetUserId]),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _blocks.doc(_blockId(currentUserId, targetUserId)),
      <String, Object>{
        'blockerId': currentUserId,
        'blockedId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _suspensionService.ensureUserAllowed(currentUserId);
    final blockRef = _blocks.doc(_blockId(currentUserId, targetUserId));

    await _firestore.runTransaction((transaction) async {
      final blockSnapshot = await transaction.get(blockRef);
      transaction.set(
        _users.doc(currentUserId),
        <String, Object>{
          'blockedUsers': FieldValue.arrayRemove(<String>[targetUserId]),
        },
        SetOptions(merge: true),
      );
      if (blockSnapshot.exists) transaction.delete(blockRef);
    });
  }

  Future<bool> isUserBlockedByMe({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final edge = await _blocks
        .doc(_blockId(currentUserId, targetUserId))
        .get();
    if (edge.exists) return true;

    final currentUser = await getUser(currentUserId);
    return currentUser?.blockedUsers.contains(targetUserId) ?? false;
  }

  Future<List<AppUser>> getBlockedUsers(String currentUserId) async {
    final currentUser = await getUser(currentUserId);
    if (currentUser == null || currentUser.blockedUsers.isEmpty) return [];

    final profiles = await Future.wait(
      currentUser.blockedUsers.map(getPublicUser),
    );
    return profiles.whereType<AppUser>().toList(growable: false);
  }

  Future<bool> isBlockedEitherWay({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final snapshots = await Future.wait(<Future<DocumentSnapshot>>[
      _blocks.doc(_blockId(currentUserId, otherUserId)).get(),
      _blocks.doc(_blockId(otherUserId, currentUserId)).get(),
    ]);
    return snapshots.any((snapshot) => snapshot.exists);
  }

  /// Retained for migration compatibility when both complete private profiles
  /// are already available. New cross-user checks use deterministic block docs.
  bool areUsersBlockedEitherWay({
    required AppUser currentUser,
    required AppUser otherUser,
  }) {
    return currentUser.blockedUsers.contains(otherUser.uid) ||
        otherUser.blockedUsers.contains(currentUser.uid);
  }

  Future<double?> getDistanceBetweenUsers(
    AppUser currentUser,
    AppUser otherUser,
  ) async {
    if (!NearbyUserPresenter.hasValidLocation(currentUser) ||
        !NearbyUserPresenter.hasValidLocation(otherUser)) {
      return null;
    }

    return Geolocator.distanceBetween(
          currentUser.latitude!,
          currentUser.longitude!,
          otherUser.latitude!,
          otherUser.longitude!,
        ) /
        1000.0;
  }

  Stream<List<AppUser>> getNearbyUsers(String currentUserId) async* {
    await _suspensionService.ensureUserAllowed(currentUserId);
    final currentUser = await getUser(currentUserId);
    if (currentUser == null) {
      yield const <AppUser>[];
      return;
    }

    final blockedIds = <String>{...currentUser.blockedUsers};
    final incomingBlocks = await _blocks
        .where('blockedId', isEqualTo: currentUserId)
        .get();
    blockedIds.addAll(
      incomingBlocks.docs
          .map((doc) => doc.data()['blockerId'])
          .whereType<String>(),
    );

    yield* _publicProfiles
        .where('isSuspended', isEqualTo: false)
        .where(
          'age',
          isGreaterThanOrEqualTo: AppConstants.minimumUserAge,
        )
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs
          .where(
            (doc) =>
                doc.id != currentUserId && !blockedIds.contains(doc.id),
          )
          .map((doc) => AppUser.fromPublicMap(doc.data(), doc.id))
          .where((user) => user.isAdult && !user.isSuspended)
          .toList(growable: false);
    });
  }

  String getLastSeenText(AppUser user) {
    if (user.isOnline) return 'online now';
    final lastSeen = user.lastSeen;
    if (lastSeen == null) return 'last seen recently';

    final difference = DateTime.now().difference(lastSeen);
    if (difference.inMinutes < 1) return 'last seen just now';
    if (difference.inMinutes < 60) {
      return 'last seen ${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return 'last seen ${difference.inHours} hr ago';
    }
    if (difference.inDays == 1) return 'last seen yesterday';
    return 'last seen recently';
  }

  Future<bool> isAdmin(String uid) async {
    final user = await getUser(uid);
    return user?.isAdmin ?? false;
  }

  Stream<List<AppUser>> getAllUsersForAdmin() {
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList(growable: false),
        );
  }

  Future<int> getTotalUsersCount() async => (await _users.get()).size;

  Future<int> getOnlineUsersCount() async {
    return (await _users.where('isOnline', isEqualTo: true).get()).size;
  }

  Future<int> getSuspendedUsersCount() async {
    return (await _users.where('isSuspended', isEqualTo: true).get()).size;
  }

  Future<Map<String, int>> getAdminDashboardStats() async {
    final results = await Future.wait<int>(<Future<int>>[
      getTotalUsersCount(),
      getOnlineUsersCount(),
      getSuspendedUsersCount(),
    ]);
    return <String, int>{
      'total': results[0],
      'online': results[1],
      'suspended': results[2],
      'offline': results[0] - results[1],
    };
  }

  Future<void> setUserSuspended({
    required String userId,
    required bool suspended,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) throw Exception('Admin not logged in');

    final admin = await getUser(currentUid);
    if (admin == null || !admin.isAdmin) {
      throw Exception('Admin permission required');
    }
    if (userId == currentUid) {
      throw Exception('Admin cannot suspend own account');
    }

    await _users.doc(userId).update(<String, Object>{
      'isSuspended': suspended,
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCurrentUserData(String uid) async {
    await _users.doc(uid).delete();
  }

  Future<bool> hasAlreadyReported({
    required String reporterId,
    required String reportedUserId,
  }) async {
    final snapshot = await _reports
        .where('reporterId', isEqualTo: reporterId)
        .where('reportedUserId', isEqualTo: reportedUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String description = '',
  }) async {
    await _suspensionService.ensureUserAllowed(reporterId);
    if (reporterId == reportedUserId) {
      throw Exception("You can't report yourself.");
    }
    if (await hasAlreadyReported(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
    )) {
      throw Exception('User already reported.');
    }

    final results = await Future.wait<AppUser?>(<Future<AppUser?>>[
      getUser(reporterId),
      getPublicUser(reportedUserId),
    ]);
    final reporter = results[0];
    final reported = results[1];

    await _reports.add(<String, Object?>{
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reporterName': reporter?.nickname ?? '',
      'reporterPhoto': reporter?.photoUrl ?? '',
      'reportedUserName': reported?.nickname ?? '',
      'reportedUserPhoto': reported?.photoUrl ?? '',
      'reason': ValidationService.reportReason(reason),
      'description': ValidationService.reportDescription(description),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': null,
      'action': null,
    });
  }

  String _blockId(String blockerId, String blockedId) =>
      '${blockerId}_$blockedId';
}
