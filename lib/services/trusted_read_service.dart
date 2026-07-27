import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/chat_preview_model.dart';
import 'local_preview_cache.dart';

class TrustedReadService {
  TrustedReadService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    LocalPreviewCache? previewCache,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _previewCache = previewCache ?? LocalPreviewCache();

  static final Map<String, List<ChatPreviewModel>> _memoryChatCache =
      <String, List<ChatPreviewModel>>{};
  static final Map<String, List<AppUser>> _memoryNearbyCache =
      <String, List<AppUser>>{};

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalPreviewCache _previewCache;

  Future<List<ChatPreviewModel>> getChatPreviews() async {
    final uid = _auth.currentUser?.uid;
    Object? callableError;
    StackTrace? callableStackTrace;

    try {
      final result = await _functions
          .httpsCallable('getPrivateChatPreviews')
          .call<Map<String, dynamic>>();
      final chats = _parseChatPreviews(result.data);
      if (uid != null) await _rememberChatPreviews(uid, chats);
      return chats;
    } catch (error, stackTrace) {
      callableError = error;
      callableStackTrace = stackTrace;
      developer.log(
        'Trusted chat preview read failed; trying Firestore fallback',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (uid != null) {
      try {
        final chats = await _getChatPreviewsFromFirestore(uid);
        await _rememberChatPreviews(uid, chats);
        return chats;
      } catch (error, stackTrace) {
        developer.log(
          'Firestore chat preview fallback failed; using device cache',
          error: error,
          stackTrace: stackTrace,
        );
      }

      final memoryChats = _memoryChatCache[uid];
      if (memoryChats != null && memoryChats.isNotEmpty) {
        return List<ChatPreviewModel>.unmodifiable(
          memoryChats.where(_hasStartedConversation),
        );
      }

      final cachedChats = await _previewCache.loadChatPreviews(uid);
      final startedCachedChats = cachedChats
          .where(_hasStartedConversation)
          .toList(growable: false);
      if (startedCachedChats.isNotEmpty) {
        _memoryChatCache[uid] = startedCachedChats;
        return startedCachedChats;
      }
    }

    if (callableError != null) {
      Error.throwWithStackTrace(
        callableError,
        callableStackTrace ?? StackTrace.current,
      );
    }
    return const <ChatPreviewModel>[];
  }

  static bool _hasStartedConversation(ChatPreviewModel chat) {
    return chat.lastMessageTime != null || chat.lastMessage.trim().isNotEmpty;
  }

  List<ChatPreviewModel> _parseChatPreviews(Map<String, dynamic> payload) {
    final rawChats = payload['chats'];
    if (rawChats is! List) return const <ChatPreviewModel>[];

    final chats = <ChatPreviewModel>[];
    for (final rawChat in rawChats) {
      if (rawChat is! Map) continue;
      final chat = ChatPreviewModel.fromMap(Map<String, dynamic>.from(rawChat));
      if (chat.chatId.isEmpty || chat.otherUserId.isEmpty) continue;
      if (!_hasStartedConversation(chat)) continue;
      chats.add(chat);
    }
    _sortChats(chats);
    return chats;
  }

  Future<List<ChatPreviewModel>> _getChatPreviewsFromFirestore(
    String uid,
  ) async {
    final results = await Future.wait([
      _firestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .limit(100)
          .get(),
      _firestore.collection('users').doc(uid).collection('blocks').get(),
    ]);
    final chatSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final ownBlocks = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final blockedByMe = ownBlocks.docs.map((document) => document.id).toSet();
    final chats = <ChatPreviewModel>[];

    for (final document in chatSnapshot.docs) {
      final data = document.data();
      final rawParticipants = data['participants'];
      if (rawParticipants is! List) continue;
      final participants = rawParticipants.whereType<String>().toList();
      if (participants.length != 2 || !participants.contains(uid)) continue;

      final lastMessage = data['lastMessage'];
      final lastMessageTime = data['lastMessageTime'];
      final hasStartedConversation =
          (lastMessage is String && lastMessage.trim().isNotEmpty) ||
          lastMessageTime is Timestamp;
      if (!hasStartedConversation) continue;

      final otherUserId = participants.firstWhere(
        (participant) => participant != uid,
        orElse: () => '',
      );
      if (otherUserId.isEmpty || blockedByMe.contains(otherUserId)) continue;

      final incomingBlock = await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('blocks')
          .doc(uid)
          .get();
      if (incomingBlock.exists) continue;

      DocumentSnapshot<Map<String, dynamic>>? otherUser;
      try {
        otherUser = await _firestore.collection('users').doc(otherUserId).get();
      } catch (_) {
        otherUser = null;
      }
      final otherData = otherUser?.data() ?? const <String, dynamic>{};
      if (otherData['isSuspended'] == true) continue;

      final unreadCounts = data['unreadCounts'] is Map
          ? Map<String, dynamic>.from(data['unreadCounts'] as Map)
          : const <String, dynamic>{};
      final readStates = data['readStates'] is Map
          ? Map<String, dynamic>.from(data['readStates'] as Map)
          : const <String, dynamic>{};
      final currentReadState = readStates[uid] is Map
          ? Map<String, dynamic>.from(readStates[uid] as Map)
          : const <String, dynamic>{};

      chats.add(
        ChatPreviewModel(
          chatId: document.id,
          otherUserId: otherUserId,
          otherUserName: otherData['nickname'] is String
              ? otherData['nickname'] as String
              : 'NearMeU user',
          otherUserPhotoUrl: otherData['photoUrl'] is String
              ? otherData['photoUrl'] as String
              : null,
          lastMessage: lastMessage is String ? lastMessage : '',
          lastMessageTime: lastMessageTime is Timestamp
              ? lastMessageTime.toDate()
              : null,
          messageType: data['lastMessageType'] is String
              ? data['lastMessageType'] as String
              : 'text',
          isUnsent:
              data['lastMessageIsUnsent'] == true ||
              data['lastMessage'] == 'This message was unsent',
          lastMessageSenderId: data['lastMessageSenderId'] is String
              ? data['lastMessageSenderId'] as String
              : null,
          unreadCount: unreadCounts[uid] is num
              ? (unreadCounts[uid] as num).toInt()
              : currentReadState['unreadCount'] is num
              ? (currentReadState['unreadCount'] as num).toInt()
              : 0,
          isOtherUserOnline: otherData['isOnline'] is bool
              ? otherData['isOnline'] as bool
              : null,
        ),
      );
    }

    _sortChats(chats);
    return chats;
  }

  Future<void> _rememberChatPreviews(
    String uid,
    List<ChatPreviewModel> chats,
  ) async {
    final startedChats = chats
        .where(_hasStartedConversation)
        .toList(growable: false);
    final immutable = List<ChatPreviewModel>.unmodifiable(startedChats);
    _memoryChatCache[uid] = immutable;
    await _previewCache.saveChatPreviews(uid, immutable);
  }

  void _sortChats(List<ChatPreviewModel> chats) {
    chats.sort((first, second) {
      final firstTime =
          first.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondTime =
          second.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondTime.compareTo(firstTime);
    });
  }

  Future<List<AppUser>> getNearbyCandidates() async {
    final uid = _auth.currentUser?.uid;
    try {
      final result = await _functions
          .httpsCallable('getNearbyCandidates')
          .call<Map<String, dynamic>>();
      final users = _parseNearbyCandidates(result.data);
      if (uid != null) {
        _memoryNearbyCache[uid] = List<AppUser>.unmodifiable(users);
      }
      return users;
    } catch (error, stackTrace) {
      developer.log(
        'Trusted nearby read failed; using the last successful result',
        error: error,
        stackTrace: stackTrace,
      );
      final cached = uid == null ? null : _memoryNearbyCache[uid];
      if (cached != null && cached.isNotEmpty) {
        return List<AppUser>.unmodifiable(cached);
      }
      rethrow;
    }
  }

  List<AppUser> _parseNearbyCandidates(Map<String, dynamic> payload) {
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
