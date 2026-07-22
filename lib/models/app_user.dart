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

  // Admin V1
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
      uid: data['uid'] ?? docId,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      gender: data['gender'] ?? '',
      lookingFor: data['lookingFor'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      city: data['city'],
      state: data['state'],
      country: data['country'],
      photoUrl: data['photoUrl'],
      age: (data['age'] as num?)?.toInt(),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      lastSeen: data['lastSeen'] is Timestamp
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      isOnline: data['isOnline'] ?? false,
      messageNotificationsEnabled:
          data['messageNotificationsEnabled'] ?? true,
      nearbyAlertsEnabled: data['nearbyAlertsEnabled'] ?? false,

      // Admin V1
      isAdmin: data['isAdmin'] ?? false,
      isSuspended: data['isSuspended'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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

      // Admin V1
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
}
