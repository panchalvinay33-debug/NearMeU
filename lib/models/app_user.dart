import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../security/location_privacy.dart';

class AppUser {
  final String uid;
  final String email;
  final String nickname;
  final String gender;
  final String lookingFor;
  final DateTime createdAt;

  /// Exact for the signed-in user's merged profile and privacy-rounded for
  /// discovery profiles.
  final double? latitude;
  final double? longitude;
  final String? locationCell;
  final String? city;
  final String? state;
  final String? country;

  final String? photoUrl;
  final int? age;

  /// Retained only for reading legacy documents during migration. New block
  /// relationships live in users/{uid}/blocks/{blockedUid}.
  final List<String> blockedUsers;
  final DateTime? lastSeen;
  final bool isOnline;

  final bool messageNotificationsEnabled;
  final bool nearbyAlertsEnabled;

  final bool isAdmin;
  final bool isSuspended;
  final int privacyVersion;

  const AppUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.gender,
    required this.lookingFor,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.locationCell,
    this.city,
    this.state,
    this.country,
    this.photoUrl,
    this.age = AppConstants.minimumUserAge,
    this.blockedUsers = const [],
    this.lastSeen,
    this.isOnline = false,
    this.messageNotificationsEnabled = true,
    this.nearbyAlertsEnabled = false,
    this.isAdmin = false,
    this.isSuspended = false,
    this.privacyVersion = 0,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String docId) {
    return AppUser(
      uid: data['uid'] ?? docId,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      gender: data['gender'] ?? '',
      lookingFor: data['lookingFor'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      latitude: (data['exactLatitude'] as num?)?.toDouble() ??
          (data['approxLatitude'] as num?)?.toDouble() ??
          (data['latitude'] as num?)?.toDouble(),
      longitude: (data['exactLongitude'] as num?)?.toDouble() ??
          (data['approxLongitude'] as num?)?.toDouble() ??
          (data['longitude'] as num?)?.toDouble(),
      locationCell: data['locationCell'],
      city: data['city'],
      state: data['state'],
      country: data['country'],
      photoUrl: data['photoUrl'],
      age: (data['age'] as num?)?.toInt() ?? AppConstants.minimumUserAge,
      blockedUsers: List<String>.from(data['blockedUsers'] ?? const <String>[]),
      lastSeen: data['lastSeen'] is Timestamp
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      isOnline: data['isOnline'] ?? false,
      messageNotificationsEnabled:
          data['messageNotificationsEnabled'] ?? true,
      nearbyAlertsEnabled: data['nearbyAlertsEnabled'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      isSuspended: data['isSuspended'] ?? false,
      privacyVersion: (data['privacyVersion'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toPublicMap() {
    final approxLatitude = LocationPrivacy.approximateLatitude(latitude);
    final approxLongitude = LocationPrivacy.approximateLongitude(longitude);
    final discoveryCell = LocationPrivacy.discoveryCellFor(latitude, longitude);
    final discoveryCells = LocationPrivacy.neighboringDiscoveryCells(
      latitude,
      longitude,
    );

    return <String, dynamic>{
      'uid': uid,
      'nickname': nickname,
      'gender': gender,
      'lookingFor': lookingFor,
      'createdAt': Timestamp.fromDate(createdAt),
      'approxLatitude': approxLatitude,
      'approxLongitude': approxLongitude,
      'locationCell': discoveryCell,
      'discoveryCells': discoveryCells,
      'state': state,
      'country': country,
      'photoUrl': photoUrl,
      'age': age ?? AppConstants.minimumUserAge,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
      'isAdmin': isAdmin,
      'isSuspended': isSuspended,
      'privacyVersion': LocationPrivacy.privacyVersion,
    };
  }

  Map<String, dynamic> toPrivateMap() {
    return <String, dynamic>{
      'email': email,
      'exactLatitude': latitude,
      'exactLongitude': longitude,
      'city': city,
      'messageNotificationsEnabled': messageNotificationsEnabled,
      'nearbyAlertsEnabled': nearbyAlertsEnabled,
      'privacyVersion': LocationPrivacy.privacyVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Public-safe compatibility serializer. Private fields must be written with
  /// [toPrivateMap].
  Map<String, dynamic> toMap() => toPublicMap();

  AppUser copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? gender,
    String? lookingFor,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    String? locationCell,
    String? city,
    String? state,
    String? country,
    String? photoUrl,
    int? age,
    List<String>? blockedUsers,
    DateTime? lastSeen,
    bool? isOnline,
    bool? messageNotificationsEnabled,
    bool? nearbyAlertsEnabled,
    bool? isAdmin,
    bool? isSuspended,
    int? privacyVersion,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationCell: locationCell ?? this.locationCell,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      messageNotificationsEnabled:
          messageNotificationsEnabled ?? this.messageNotificationsEnabled,
      nearbyAlertsEnabled: nearbyAlertsEnabled ?? this.nearbyAlertsEnabled,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuspended: isSuspended ?? this.isSuspended,
      privacyVersion: privacyVersion ?? this.privacyVersion,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;

  bool get isAdult => age != null && age! >= AppConstants.minimumUserAge;
}
