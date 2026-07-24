import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_user.dart';
import '../models/chat_preview_model.dart';

class TrustedReadService {
  TrustedReadService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<List<ChatPreviewModel>> getChatPreviews() async {
    final result = await _functions
        .httpsCallable('getPrivateChatPreviews')
        .call<Map<String, dynamic>>();
    final payload = Map<String, dynamic>.from(result.data);
    final rawChats = payload['chats'];
    if (rawChats is! List) return const <ChatPreviewModel>[];

    final chats = <ChatPreviewModel>[];
    for (final rawChat in rawChats) {
      if (rawChat is! Map) continue;
      final data = Map<String, dynamic>.from(rawChat);
      final chatId = data['chatId'];
      final otherUserId = data['otherUserId'];
      if (chatId is! String || otherUserId is! String) continue;

      final timeMillis = data['lastMessageTimeMillis'];
      chats.add(
        ChatPreviewModel(
          chatId: chatId,
          otherUserId: otherUserId,
          otherUserName: data['otherUserName'] is String
              ? data['otherUserName'] as String
              : 'NearMeU user',
          lastMessage: data['lastMessage'] is String
              ? data['lastMessage'] as String
              : '',
          lastMessageTime: timeMillis is num
              ? DateTime.fromMillisecondsSinceEpoch(timeMillis.toInt())
              : null,
          messageType: data['messageType'] is String
              ? data['messageType'] as String
              : 'text',
          isUnsent: data['isUnsent'] == true,
          lastMessageSenderId: data['lastMessageSenderId'] is String
              ? data['lastMessageSenderId'] as String
              : null,
          lastMessageSeen: data['lastMessageSeen'] is bool
              ? data['lastMessageSeen'] as bool
              : null,
          unreadCount: data['unreadCount'] is num
              ? (data['unreadCount'] as num).toInt()
              : 0,
          isOtherUserOnline: data['isOtherUserOnline'] is bool
              ? data['isOtherUserOnline'] as bool
              : null,
        ),
      );
    }

    chats.sort((first, second) {
      final firstTime =
          first.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondTime =
          second.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondTime.compareTo(firstTime);
    });
    return chats;
  }

  Future<List<AppUser>> getNearbyCandidates() async {
    final result = await _functions
        .httpsCallable('getNearbyCandidates')
        .call<Map<String, dynamic>>();
    final payload = Map<String, dynamic>.from(result.data);
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
