import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../security/location_privacy.dart';
import '../security/suspension_service.dart';
import '../utils/nearby_user_presenter.dart';
import 'validation_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SuspensionService _suspensionService = SuspensionService();

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _privateProfileRef(String uid) {
    return _firestore.collection('privateProfiles').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _blocksRef(String uid) {
    return _userRef(uid).collection('blocks');
  }

  Future<void> createUser(AppUser user) async {
    ValidationService.age(user.age ?? AppConstants.minimumUserAge);
    final batch = _firestore.batch();
    batch.set(_userRef(user.uid), user.toPublicMap());
    batch.set(_privateProfileRef(user.uid), user.toPrivateMap());
    await batch.commit();
    await _writeLegacyBlocks(user.uid, user.blockedUsers);
  }

  Future<void> saveUser(AppUser user) async {
    ValidationService.age(user.age ?? AppConstants.minimumUserAge);
    final batch = _firestore.batch();
    batch.set(_userRef(user.uid), user.toPublicMap(), SetOptions(merge: true));
    batch.set(
      _privateProfileRef(user.uid),
      user.toPrivateMap(),
      SetOptions(merge: true),
    );
    await batch.commit();
    await _writeLegacyBlocks(user.uid, user.blockedUsers);
  }

  Future<AppUser?> getUser(String uid) async {
    final document = await _userRef(uid).get();
    if (!document.exists || document.data() == null) return null;
    return _hydrateUser(uid, document.data()!);
  }

  Stream<AppUser?> streamUser(String uid) {
    return _userRef(uid).snapshots().asyncMap((document) async {
      if (!document.exists || document.data() == null) return null;
      return _hydrateUser(uid, document.data()!);
    });
  }

  Future<AppUser> _hydrateUser(
    String uid,
    Map<String, dynamic> publicData,
  ) async {
    if (FirebaseAuth.instance.currentUser?.uid == uid) {
      await _migrateLegacyPrivateData(uid, publicData);
      final refreshedPublic = await _userRef(uid).get();
      final merged = Map<String, dynamic>.from(
        refreshedPublic.data() ?? publicData,
      );
      final privateDocument = await _privateProfileRef(uid).get();
      if (privateDocument.exists && privateDocument.data() != null) {
        merged.addAll(privateDocument.data()!);
      }
      final blocks = await _blocksRef(uid).get();
      merged['blockedUsers'] = blocks.docs.map((document) => document.id).toList();
      return AppUser.fromMap(merged, uid);
    }
    return AppUser.fromMap(publicData, uid);
  }

  Future<void> _migrateLegacyPrivateData(
    String uid,
    Map<String, dynamic> publicData,
  ) async {
    const legacyKeys = <String>{
      'email',
      'latitude',
      'longitude',
      'city',
      'blockedUsers',
      'messageNotificationsEnabled',
      'nearbyAlertsEnabled',
    };
    final needsMigration =
        (publicData['privacyVersion'] as num?)?.toInt() !=
            LocationPrivacy.privacyVersion ||
        legacyKeys.any(publicData.containsKey);
    if (!needsMigration) return;

    final latitude = (publicData['latitude'] as num?)?.toDouble() ??
        (publicData['approxLatitude'] as num?)?.toDouble();
    final longitude = (publicData['longitude'] as num?)?.toDouble() ??
        (publicData['approxLongitude'] as num?)?.toDouble();
    final blockedUsers = List<String>.from(
      publicData['blockedUsers'] ?? const <String>[],
    );
    final nickname = publicData['nickname'] is String &&
            (publicData['nickname'] as String).trim().isNotEmpty
        ? (publicData['nickname'] as String).trim()
        : 'User';
    final gender = _allowedGender(publicData['gender']);
    final lookingFor = _allowedLookingFor(publicData['lookingFor']);
    final age = publicData['age'] is int
        ? (publicData['age'] as int).clamp(
            AppConstants.minimumUserAge,
            AppConstants.maximumUserAge,
          )
        : AppConstants.minimumUserAge;

    final privateData = <String, dynamic>{
      'email': publicData['email'] is String ? publicData['email'] : '',
      'exactLatitude': latitude,
      'exactLongitude': longitude,
      'city': publicData['city'] is String ? publicData['city'] : null,
      'messageNotificationsEnabled':
          publicData['messageNotificationsEnabled'] is bool
          ? publicData['messageNotificationsEnabled']
          : true,
      'nearbyAlertsEnabled': publicData['nearbyAlertsEnabled'] is bool
          ? publicData['nearbyAlertsEnabled']
          : false,
      'privacyVersion': LocationPrivacy.privacyVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final publicReplacement = <String, dynamic>{
      'uid': uid,
      'nickname': nickname,
      'gender': gender,
      'lookingFor': lookingFor,
      'createdAt': publicData['createdAt'] is Timestamp
          ? publicData['createdAt']
          : FieldValue.serverTimestamp(),
      'approxLatitude': LocationPrivacy.approximateLatitude(latitude),
      'approxLongitude': LocationPrivacy.approximateLongitude(longitude),
      'locationCell': LocationPrivacy.discoveryCellFor(latitude, longitude),
      'discoveryCells': LocationPrivacy.neighboringDiscoveryCells(
        latitude,
        longitude,
      ),
      'state': publicData['state'] is String ? publicData['state'] : null,
      'country': publicData['country'] is String ? publicData['country'] : null,
      'photoUrl': publicData['photoUrl'] is String ? publicData['photoUrl'] : null,
      'age': age,
      'lastSeen': publicData['lastSeen'] is Timestamp
          ? publicData['lastSeen']
          : null,
      'isOnline': publicData['isOnline'] is bool
          ? publicData['isOnline']
          : false,
      'isAdmin': publicData['isAdmin'] is bool ? publicData['isAdmin'] : false,
      'isSuspended': publicData['isSuspended'] is bool
          ? publicData['isSuspended']
          : false,
      'privacyVersion': LocationPrivacy.privacyVersion,
    };

    final batch = _firestore.batch();
    batch.set(_privateProfileRef(uid), privateData, SetOptions(merge: true));
    batch.set(_userRef(uid), publicReplacement);
    await batch.commit();
    await _writeLegacyBlocks(uid, blockedUsers);
  }

  String _allowedGender(dynamic value) {
    return value is String &&
            const <String>{'Male', 'Female', 'Other', 'Both', ''}.contains(value)
        ? value
        : '';
  }

  String _allowedLookingFor(dynamic value) {
    return value is String &&
            const <String>{'Male', 'Female', 'Both', ''}.contains(value)
        ? value
        : '';
  }

  Future<void> _writeLegacyBlocks(
    String uid,
    Iterable<String> blockedUsers,
  ) async {
    final validIds = blockedUsers
        .where((blockedUid) => blockedUid.isNotEmpty && blockedUid != uid)
        .toSet()
        .toList();
    for (var start = 0; start < validIds.length; start += 400) {
      final batch = _firestore.batch();
      final end = (start + 400).clamp(0, validIds.length).toInt();
      for (final blockedUid in validIds.sublist(start, end)) {
        batch.set(_blocksRef(uid).doc(blockedUid), <String, dynamic>{
          'blockerId': uid,
          'blockedUserId': blockedUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Stream<DateTime?> watchLastSeen(String uid) {
    return _userRef(uid).snapshots().map((document) {
      final data = document.data();
      if (!document.exists || data == null) return null;
      return data['lastSeen'] is Timestamp
          ? (data['lastSeen'] as Timestamp).toDate()
          : null;
    });
  }

  String? getCurrentUserId() => FirebaseAuth.instance.currentUser?.uid;

  bool isProfileComplete(AppUser user) {
    return user.nickname.trim().isNotEmpty &&
        user.gender.trim().isNotEmpty &&
        user.lookingFor.trim().isNotEmpty &&
        user.age != null &&
        user.age! >= AppConstants.minimumUserAge;
  }

  String normalizeGender(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'male') return 'Male';
    if (normalized == 'female') return 'Female';
    if (normalized == 'other') return 'Other';
    if (normalized == 'both') return 'Both';
    return '';
  }

  String normalizeLookingFor(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'male') return 'Male';
    if (normalized == 'female') return 'Female';
    if (normalized == 'both') return 'Both';
    return '';
  }

  Future<void> updateNickname(String uid, String nickname) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _userRef(uid).update({
      'nickname': ValidationService.nickname(nickname),
    });
  }

  Future<void> updateAge(String uid, int age) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _userRef(uid).update({'age': ValidationService.age(age)});
  }

  Future<void> updateGender(String uid, String gender) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _userRef(uid).update({
      'gender': ValidationService.profileChoice(gender, 'gender'),
    });
  }

  Future<void> updateLookingFor(String uid, String lookingFor) async {
    await _suspensionService.ensureUserAllowed(uid);
    await _userRef(uid).update({
      'lookingFor': ValidationService.profileChoice(
        lookingFor,
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
    await _userRef(uid).set(<String, dynamic>{
      'nickname': ValidationService.nickname(nickname),
      'age': ValidationService.age(age),
      'gender': ValidationService.profileChoice(gender, 'gender'),
      'lookingFor': ValidationService.profileChoice(
        lookingFor,
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
    final safeLatitude = ValidationService.latitude(latitude);
    final safeLongitude = ValidationService.longitude(longitude);
    final batch = _firestore.batch();
    batch.set(_userRef(uid), <String, dynamic>{
      'approxLatitude': LocationPrivacy.approximateLatitude(safeLatitude),
      'approxLongitude': LocationPrivacy.approximateLongitude(safeLongitude),
      'locationCell': LocationPrivacy.discoveryCellFor(
        safeLatitude,
        safeLongitude,
      ),
      'discoveryCells': LocationPrivacy.neighboringDiscoveryCells(
        safeLatitude,
        safeLongitude,
      ),
      'state': state,
      'country': country,
      'privacyVersion': LocationPrivacy.privacyVersion,
    }, SetOptions(merge: true));
    batch.set(_privateProfileRef(uid), <String, dynamic>{
      'exactLatitude': safeLatitude,
      'exactLongitude': safeLongitude,
      'city': city,
      'privacyVersion': LocationPrivacy.privacyVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
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
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
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
        final place = placemarks.first;
        city = place.locality?.trim().isNotEmpty == true
            ? place.locality!.trim()
            : (place.subAdministrativeArea?.trim().isNotEmpty == true
                  ? place.subAdministrativeArea!.trim()
                  : null);
        state = place.administrativeArea;
        country = place.country;
      }
    } catch (error) {
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
    await _userRef(uid).set(<String, dynamic>{
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': false,
    }, SetOptions(merge: true));
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    await _userRef(uid).set(<String, dynamic>{
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateMessageNotifications({
    required String uid,
    required bool enabled,
  }) async {
    await _privateProfileRef(uid).set(<String, dynamic>{
      'messageNotificationsEnabled': enabled,
      'privacyVersion': LocationPrivacy.privacyVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNearbyAlerts({
    required String uid,
    required bool enabled,
  }) async {
    await _privateProfileRef(uid).set(<String, dynamic>{
      'nearbyAlertsEnabled': enabled,
      'privacyVersion': LocationPrivacy.privacyVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _suspensionService.ensureUserAllowed(currentUserId);
    if (currentUserId == targetUserId) throw Exception('Cannot block yourself.');
    await _blocksRef(currentUserId).doc(targetUserId).set(<String, dynamic>{
      'blockerId': currentUserId,
      'blockedUserId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _blocksRef(currentUserId).doc(targetUserId).delete();
  }

  Future<bool> isUserBlockedByMe({
    required String currentUserId,
    required String targetUserId,
  }) async {
    return (await _blocksRef(currentUserId).doc(targetUserId).get()).exists;
  }

  Future<List<AppUser>> getBlockedUsers(String currentUserId) async {
    final blockDocuments = await _blocksRef(currentUserId).get();
    final users = await Future.wait(
      blockDocuments.docs.map((document) => getUser(document.id)),
    );
    return users.whereType<AppUser>().toList();
  }

  Future<bool> isBlockedEitherWay({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final results = await Future.wait<
        DocumentSnapshot<Map<String, dynamic>>>(<
      Future<DocumentSnapshot<Map<String, dynamic>>>
    >[
      _blocksRef(currentUserId).doc(otherUserId).get(),
      _blocksRef(otherUserId).doc(currentUserId).get(),
    ]);
    return results.any((document) => document.exists);
  }

  bool areUsersBlockedEitherWay({
    required AppUser currentUser,
    required AppUser otherUser,
  }) {
    return currentUser.blockedUsers.contains(otherUser.uid) ||
        otherUser.blockedUsers.contains(currentUser.uid);
  }

  bool areUsersMutuallyCompatible({
    required AppUser currentUser,
    required AppUser otherUser,
  }) {
    return _preferenceMatches(currentUser.lookingFor, otherUser.gender) &&
        _preferenceMatches(otherUser.lookingFor, currentUser.gender);
  }

  bool _preferenceMatches(String preference, String gender) {
    return preference == 'Both' || preference == gender;
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
    if (currentUser == null || !currentUser.hasLocation) {
      yield const <AppUser>[];
      return;
    }

    final cells = LocationPrivacy.neighboringDiscoveryCells(
      currentUser.latitude,
      currentUser.longitude,
    );
    if (cells.isEmpty) {
      yield const <AppUser>[];
      return;
    }

    final ownBlocks = await _blocksRef(currentUserId).get();
    final blockedByMe = ownBlocks.docs.map((document) => document.id).toSet();

    yield* _firestore
        .collection('users')
        .where('locationCell', whereIn: cells)
        .limit(AppConstants.nearbyPageSize)
        .snapshots(includeMetadataChanges: false)
        .asyncMap((snapshot) async {
      final candidates = <AppUser>[];
      for (final document in snapshot.docs) {
        if (document.id == currentUserId) continue;
        final user = AppUser.fromMap(document.data(), document.id);
        if (user.isSuspended || !user.isAdult) continue;
        if (!areUsersMutuallyCompatible(
          currentUser: currentUser,
          otherUser: user,
        )) {
          continue;
        }
        if (blockedByMe.contains(user.uid)) continue;
        final blockedMe = await _blocksRef(user.uid).doc(currentUserId).get();
        if (blockedMe.exists) continue;
        candidates.add(user);
      }
      return candidates;
    });
  }

  String getLastSeenText(AppUser user) {
    if (user.isOnline) return 'online now';
    if (user.lastSeen == null) return 'last seen recently';
    final difference = DateTime.now().difference(user.lastSeen!);
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
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => AppUser.fromMap(document.data(), document.id))
              .toList(),
        );
  }

  Future<int> getTotalUsersCount() async {
    return (await _firestore.collection('users').get()).docs.length;
  }

  Future<int> getOnlineUsersCount() async {
    return (await _firestore
            .collection('users')
            .where('isOnline', isEqualTo: true)
            .get())
        .docs
        .length;
  }

  Future<int> getSuspendedUsersCount() async {
    return (await _firestore
            .collection('users')
            .where('isSuspended', isEqualTo: true)
            .get())
        .docs
        .length;
  }

  Future<Map<String, int>> getAdminDashboardStats() async {
    final results = await Future.wait(<Future<int>>[
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
    await _userRef(userId).update(<String, dynamic>{
      'isSuspended': suspended,
      'isOnline': suspended ? false : FieldValue.delete(),
    });
  }

  Future<void> deleteCurrentUserData(String uid) async {
    final blocks = await _blocksRef(uid).get();
    for (var start = 0; start < blocks.docs.length; start += 400) {
      final batch = _firestore.batch();
      final end = (start + 400).clamp(0, blocks.docs.length).toInt();
      for (final document in blocks.docs.sublist(start, end)) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
    final batch = _firestore.batch();
    batch.delete(_privateProfileRef(uid));
    batch.delete(_userRef(uid));
    await batch.commit();
  }

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
    if (await hasAlreadyReported(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
    )) {
      throw Exception('User already reported.');
    }
    final reporter = await getUser(reporterId);
    final reported = await getUser(reportedUserId);
    await _reports.add(<String, dynamic>{
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
