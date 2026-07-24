import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_preview_model.dart';

class LocalPreviewCache {
  LocalPreviewCache({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _chatPrefix = 'chat_previews_v1_';
  static const int _maximumCachedChats = 100;

  final SharedPreferencesAsync _preferences;

  String _chatKey(String uid) => '$_chatPrefix$uid';

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
        final data = Map<String, dynamic>.from(item);
        final chat = ChatPreviewModel.fromMap(data);
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
    final safeChats = chats.take(_maximumCachedChats).map((chat) {
      return chat.toMap();
    }).toList(growable: false);
    await _preferences.setString(_chatKey(uid), jsonEncode(safeChats));
  }

  Future<void> clearChatPreviews(String uid) {
    return _preferences.remove(_chatKey(uid));
  }
}
