import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../utils/nearby_user_presenter.dart';
import '../models/app_user.dart';
import '../security/suspension_service.dart';
import 'validation_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SuspensionService _suspensionService = SuspensionService();

  Future<void> createUser(AppUser user) async {
    ValidationService.age(user.age ?? AppConstants.minimumUserAge);
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> saveUser(AppUser user) async {
    ValidationService.age(user.age ?? AppConstants.minimumUserAge);
    await _firestore.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  Stream<AppUser?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<DateTime?> watchLastSeen(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;

      if (data['lastSeen'] is Timestamp) {
        return (data['lastSeen'] as Timestamp).toDate();
      }

      return null;
    });
  }

  String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  bool isProfileComplete(AppUser user) {
    return user.nickname.trim().isNotEmpty &&
        user.gender.trim().isNotEmpty &&
        user.lookingFor.trim().isNotEmpty &&
        user.age != null &&
        user.age! >= AppConstants.minimumUserAge;
  }

  String normalizeGender(String value) {
    final v = value.trim().toLowerCase();

    if (v == 'male') return 'Male';
    if (v == 'female') return 'Female';
    if (v == 'both') return 'Both';

    return '';
  }

  String normalizeLookingFor(String value) {
    final v = value.trim().toLowerCase();

    if (v == 'male') return 'Male';
    if (v == 'female') return 'Female';
    if (v == 'both') return 'Both';

    return '';
  }

  Future<void> updateNickname(
    String uid,
    String nickname,
  ) async {
    await _suspensionService.ensureUserAllowed(uid);

    await _firestore.collection('users').doc(uid).update({
      'nickname': ValidationService.nickname(nickname),
    });
  }

  Future<void> updateAge(
    String uid,
    int age,
  ) async {
    await _suspensionService.ensureUserAllowed(uid);

    await _firestore.collection('users').doc(uid).update({
      'age': ValidationService.age(age),
    });
  }

  Future<void> updateGender(
    String uid,
    String gender,
  ) async {
    await _suspensionService.ensureUserAllowed(uid);

    await _firestore.collection('users').doc(uid).update({
      'gender': ValidationService.profileChoice(gender, 'gender'),
    });
  }

  Future<void> updateLookingFor(
    String uid,
    String lookingFor,
  ) async {
    await _suspensionService.ensureUserAllowed(uid);

    await _firestore.collection('users').doc(uid).update({
      'lookingFor': ValidationService.profileChoice(lookingFor, 'preference'),
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

    await _firestore.collection('users').doc(uid).set({
      'nickname': ValidationService.nickname(nickname),
      'age': ValidationService.age(age),
      'gender': ValidationService.profileChoice(gender, 'gender'),
      'lookingFor': ValidationService.profileChoice(lookingFor, 'preference'),
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

    await _firestore.collection('users').doc(uid).set({
      'latitude': ValidationService.latitude(latitude),
      'longitude': ValidationService.longitude(longitude),
      'city': city,
      'state': state,
      'country': country,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserLocation(String uid) async {
    await _suspensionService.ensureUserAllowed(uid);

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );

    String? city;
    String? state;
    String? country;

    try {
      final placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        city = p.locality?.trim().isNotEmpty == true
            ? p.locality!.trim()
            : (p.subAdministrativeArea
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? p.subAdministrativeArea!.trim()
                : null);

        state = p.administrativeArea;
        country = p.country;
      }
    } catch (error) {
      // Reverse geocoding is best-effort; keep valid coordinates when it fails.
      developer.log('Reverse geocoding failed', error: error);
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

    await _firestore.collection('users').doc(uid).set({
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': false,
    }, SetOptions(merge: true));
  }

  Future<void> setOnlineStatus(
    String uid,
    bool isOnline,
  ) async {
    await _firestore.collection('users').doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateMessageNotifications({
    required String uid,
    required bool enabled,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'messageNotificationsEnabled': enabled,
    }, SetOptions(merge: true));
  }

  Future<void> updateNearbyAlerts({
    required String uid,
    required bool enabled,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'nearbyAlertsEnabled': enabled,
    }, SetOptions(merge: true));
  }

  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .set({
      'blockedUsers':
          FieldValue.arrayUnion([targetUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .set({
      'blockedUsers':
          FieldValue.arrayRemove([targetUserId]),
    }, SetOptions(merge: true));
  }

  Future<bool> isUserBlockedByMe({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final currentUser =
        await getUser(currentUserId);

    if (currentUser == null) return false;

    return currentUser.blockedUsers
        .contains(targetUserId);
  }

  Future<List<AppUser>> getBlockedUsers(
    String currentUserId,
  ) async {
    final currentUser =
        await getUser(currentUserId);

    if (currentUser == null ||
        currentUser.blockedUsers.isEmpty) {
      return [];
    }

    final List<AppUser> blocked = [];

    for (final blockedUid
        in currentUser.blockedUsers) {
      final user = await getUser(blockedUid);

      if (user != null) {
        blocked.add(user);
      }
    }

    return blocked;
  }

  Future<bool> isBlockedEitherWay({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final currentUser =
        await getUser(currentUserId);

    final otherUser =
        await getUser(otherUserId);

    if (currentUser == null ||
        otherUser == null) {
      return false;
    }

    return areUsersBlockedEitherWay(
      currentUser: currentUser,
      otherUser: otherUser,
    );
  }

  bool areUsersBlockedEitherWay({
    required AppUser currentUser,
    required AppUser otherUser,
  }) {
    final currentBlocked =
        currentUser.blockedUsers
            .contains(otherUser.uid);

    final otherBlocked =
        otherUser.blockedUsers
            .contains(currentUser.uid);

    return currentBlocked || otherBlocked;
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

  Stream<List<AppUser>> getNearbyUsers(
    String currentUserId,
  ) async* {
    await _suspensionService.ensureUserAllowed(currentUserId);

    final currentUser =
        await getUser(currentUserId);

    if (currentUser == null) {
      yield [];
      return;
    }

    // Load the full registered-user collection and apply Nearby eligibility in
    // Dart. Firestore `where` clauses on `isSuspended` and `age` exclude older
    // valid profiles where those fields are missing; AppUser supplies safe
    // defaults for those legacy documents.
    yield* _firestore
        .collection('users')
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      final List<AppUser> users = [];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) {
          continue;
        }

        final user =
            AppUser.fromMap(
          doc.data(),
          doc.id,
        );

        // Suspended users do not appear in Nearby.
        if (user.isSuspended || !user.isAdult) {
          continue;
        }

        if (areUsersBlockedEitherWay(
          currentUser: currentUser,
          otherUser: user,
        )) {
          continue;
        }

        users.add(user);
      }

      return users;
    });
  }

  String getLastSeenText(AppUser user) {
    if (user.isOnline) {
      return 'online now';
    }

    if (user.lastSeen == null) {
      return 'last seen recently';
    }

    final diff =
        DateTime.now().difference(
      user.lastSeen!,
    );

    if (diff.inMinutes < 1) {
      return 'last seen just now';
    }

    if (diff.inMinutes < 60) {
      return 'last seen ${diff.inMinutes} min ago';
    }

    if (diff.inHours < 24) {
      return 'last seen ${diff.inHours} hr ago';
    }

    if (diff.inDays == 1) {
      return 'last seen yesterday';
    }

    return 'last seen recently';
  }

  // ==================================================
  // ADMIN V1
  // ==================================================

  Future<bool> isAdmin(String uid) async {
    final user = await getUser(uid);
    return user?.isAdmin ?? false;
  }

  Stream<List<AppUser>> getAllUsersForAdmin() {
    return _firestore
        .collection('users')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => AppUser.fromMap(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
    });
  }

  Future<int> getTotalUsersCount() async {
    final snapshot =
        await _firestore
            .collection('users')
            .get();

    return snapshot.docs.length;
  }

  Future<int> getOnlineUsersCount() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where(
              'isOnline',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs.length;
  }

  Future<int> getSuspendedUsersCount() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where(
              'isSuspended',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs.length;
  }

  Future<Map<String, int>>
      getAdminDashboardStats() async {
    final results = await Future.wait([
      getTotalUsersCount(),
      getOnlineUsersCount(),
      getSuspendedUsersCount(),
    ]);

    return {
      'total': results[0],
      'online': results[1],
      'suspended': results[2],
      'offline':
          results[0] - results[1],
    };
  }

  Future<void> setUserSuspended({
    required String userId,
    required bool suspended,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      throw Exception('Admin not logged in');
    }

    final admin = await getUser(currentUid);

    if (admin == null || !admin.isAdmin) {
      throw Exception('Admin permission required');
    }

    if (userId == currentUid) {
      throw Exception('Admin cannot suspend own account');
    }

    await _firestore.collection('users').doc(userId).update({
      'isSuspended': suspended,
      'isOnline': suspended ? false : FieldValue.delete(),
    });
  }

  Future<void> deleteCurrentUserData(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // ==================================================
  // REPORT SYSTEM
  // ==================================================

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

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

    final already = await hasAlreadyReported(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
    );

    if (already) {
      throw Exception("User already reported.");
    }

    final reporter = await getUser(reporterId);
    final reported = await getUser(reportedUserId);

    await _reports.add({
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
}
