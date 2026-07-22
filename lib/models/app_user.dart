import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

class AppUser {
  final String uid;
  final String email;
  final String nickname;
  final String gender;
  final String lookingFor;
  final DateTime createdAt;

  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;

  final String? photoUrl;
  final int? age;

  final List<String> blockedUsers;
  final DateTime? lastSeen;
  final bool isOnline;

  final bool messageNotificationsEnabled;
  final bool nearbyAlertsEnabled;

  final bool isAdmin;
  final bool isSuspended;

  const AppUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.gender,
    required this.lookingFor,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.photoUrl,
    this.age,
    this.blockedUsers = const [],
    this.lastSeen,
    this.isOnline = false,
    this.messageNotificationsEnabled = true,
    this.nearbyAlertsEnabled = false,
    this.isAdmin = false,
    this.isSuspended = false,
  });

  factory AppUser.fromMap(
    Map<String, dynamic> data,
    String docId,
  ) {
    return AppUser(
      uid: (data['uid'] as String?) ?? docId,
      email: (data['email'] as String?) ?? '',
      nickname: (data['nickname'] as String?) ?? '',
      gender: (data['gender'] as String?) ?? '',
      lookingFor: (data['lookingFor'] as String?) ?? '',
      createdAt: _date(data['createdAt']),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      photoUrl: data['photoUrl'] as String?,
      age: (data['age'] as num?)?.toInt(),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? const []),
      lastSeen: _nullableDate(data['lastSeen']),
      isOnline: data['isOnline'] == true,
      messageNotificationsEnabled:
          data['messageNotificationsEnabled'] != false,
      nearbyAlertsEnabled: data['nearbyAlertsEnabled'] == true,
      isAdmin: data['isAdmin'] == true,
      isSuspended: data['isSuspended'] == true,
    );
  }

  /// Parses the intentionally limited document exposed to other active users.
  /// Exact coordinates, email, block lists, notification preferences, and
  /// administrator flags never exist in this document.
  factory AppUser.fromPublicMap(
    Map<String, dynamic> data,
    String docId,
  ) {
    return AppUser(
      uid: (data['uid'] as String?) ?? docId,
      email: '',
      nickname: (data['nickname'] as String?) ?? '',
      gender: (data['gender'] as String?) ?? '',
      lookingFor: (data['lookingFor'] as String?) ?? '',
      createdAt: _date(data['createdAt']),
      latitude: (data['approxLatitude'] as num?)?.toDouble(),
      longitude: (data['approxLongitude'] as num?)?.toDouble(),
      state: data['state'] as String?,
      photoUrl: data['photoUrl'] as String?,
      age: (data['age'] as num?)?.toInt(),
      lastSeen: _nullableDate(data['lastSeen']),
      isOnline: data['isOnline'] == true,
      isSuspended: data['isSuspended'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'gender': gender,
      'lookingFor': lookingFor,
      'createdAt': Timestamp.fromDate(createdAt),
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'photoUrl': photoUrl,
      'age': age,
      'blockedUsers': blockedUsers,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
      'messageNotificationsEnabled': messageNotificationsEnabled,
      'nearbyAlertsEnabled': nearbyAlertsEnabled,
      'isAdmin': isAdmin,
      'isSuspended': isSuspended,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? gender,
    String? lookingFor,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
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
    );
  }

  bool get hasLocation => latitude != null && longitude != null;

  bool get isAdult =>
      age != null &&
      age! >= AppConstants.minimumUserAge &&
      age! <= AppConstants.maximumUserAge;

  static DateTime _date(Object? value) {
    return _nullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
