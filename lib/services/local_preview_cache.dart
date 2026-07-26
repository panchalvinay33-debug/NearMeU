import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/chat_preview_model.dart';

class LocalPreviewCache {
  LocalPreviewCache({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _chatPrefix = 'chat_previews_v1_';
  static const String _nearbyPrefix = 'nearby_candidates_v1_';
  static const int _maximumCachedChats = 100;
  static const int _maximumCachedNearbyUsers = 100;

  final SharedPreferencesAsync _preferences;

  String _chatKey(String uid) => '$_chatPrefix$uid';
  String _nearbyKey(String uid) => '$_nearbyPrefix$uid';

  Future<List<ChatPreviewModel>> loadChatPreviews(String uid) async {
    final encoded = await _preferences.getString(_chatKey(uid));
    if (encoded == null || encoded.isEmpty) {
      return const <ChatPreviewModel>[];
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const <ChatPreviewModel>[];

      final chats = <ChatPreviewModel>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final chat = ChatPreviewModel.fromMap(Map<String, dynamic>.from(item));
        if (chat.chatId.isEmpty || chat.otherUserId.isEmpty) continue;
        chats.add(chat);
      }

      chats.sort((first, second) {
        final firstTime =
            first.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final secondTime =
            second.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return secondTime.compareTo(firstTime);
      });
      return chats.take(_maximumCachedChats).toList(growable: false);
    } on FormatException {
      await clearChatPreviews(uid);
      return const <ChatPreviewModel>[];
    }
  }

  Future<void> saveChatPreviews(
    String uid,
    List<ChatPreviewModel> chats,
  ) async {
    final safeChats = chats
        .take(_maximumCachedChats)
        .map((chat) {
          return chat.toMap();
        })
        .toList(growable: false);
    await _preferences.setString(_chatKey(uid), jsonEncode(safeChats));
  }

  Future<void> clearChatPreviews(String uid) {
    return _preferences.remove(_chatKey(uid));
  }

  Future<List<AppUser>> loadNearbyCandidates(String uid) async {
    final encoded = await _preferences.getString(_nearbyKey(uid));
    if (encoded == null || encoded.isEmpty) return const <AppUser>[];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const <AppUser>[];

      final users = <AppUser>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item);
        final candidateUid = data['uid'];
        if (candidateUid is! String || candidateUid.isEmpty) continue;
        users.add(
          AppUser(
            uid: candidateUid,
            email: '',
            nickname: data['nickname'] is String
                ? data['nickname'] as String
                : 'NearMeU user',
            gender: data['gender'] is String ? data['gender'] as String : '',
            lookingFor: data['lookingFor'] is String
                ? data['lookingFor'] as String
                : '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              data['createdAtMillis'] is num
                  ? (data['createdAtMillis'] as num).toInt()
                  : 0,
            ),
            latitude: data['latitude'] is num
                ? (data['latitude'] as num).toDouble()
                : null,
            longitude: data['longitude'] is num
                ? (data['longitude'] as num).toDouble()
                : null,
            locationCell: data['locationCell'] is String
                ? data['locationCell'] as String
                : null,
            state: data['state'] is String ? data['state'] as String : null,
            country: data['country'] is String
                ? data['country'] as String
                : null,
            photoUrl: data['photoUrl'] is String
                ? data['photoUrl'] as String
                : null,
            age: data['age'] is num ? (data['age'] as num).toInt() : 18,
            lastSeen: data['lastSeenMillis'] is num
                ? DateTime.fromMillisecondsSinceEpoch(
                    (data['lastSeenMillis'] as num).toInt(),
                  )
                : null,
            isOnline: data['isOnline'] == true,
            isAdmin: data['isAdmin'] == true,
            isSuspended: data['isSuspended'] == true,
            privacyVersion: data['privacyVersion'] is num
                ? (data['privacyVersion'] as num).toInt()
                : 0,
          ),
        );
      }
      return users.take(_maximumCachedNearbyUsers).toList(growable: false);
    } on FormatException {
      await clearNearbyCandidates(uid);
      return const <AppUser>[];
    }
  }

  Future<void> saveNearbyCandidates(String uid, List<AppUser> users) async {
    final safeUsers = users
        .take(_maximumCachedNearbyUsers)
        .map((user) {
          return <String, dynamic>{
            'uid': user.uid,
            'nickname': user.nickname,
            'gender': user.gender,
            'lookingFor': user.lookingFor,
            'createdAtMillis': user.createdAt.millisecondsSinceEpoch,
            'latitude': user.latitude,
            'longitude': user.longitude,
            'locationCell': user.locationCell,
            'state': user.state,
            'country': user.country,
            'photoUrl': user.photoUrl,
            'age': user.age,
            'lastSeenMillis': user.lastSeen?.millisecondsSinceEpoch,
            'isOnline': user.isOnline,
            'isAdmin': user.isAdmin,
            'isSuspended': user.isSuspended,
            'privacyVersion': user.privacyVersion,
          };
        })
        .toList(growable: false);
    await _preferences.setString(_nearbyKey(uid), jsonEncode(safeUsers));
  }

  Future<void> clearNearbyCandidates(String uid) {
    return _preferences.remove(_nearbyKey(uid));
  }
}
