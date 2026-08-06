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

  Future<HttpsCallableResult<Map<String, dynamic>>> _readChatPreviews() {
    return _functions
        .httpsCallable('getPrivateChatPreviews')
        .call<Map<String, dynamic>>();
  }

  Future<HttpsCallableResult<Map<String, dynamic>>>
  _readChatPreviewsWithAuthRetry() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Please sign in again.',
      );
    }

    // Match the proven Nearby startup path: after reinstall/login, make sure
    // Firebase Auth has produced a usable ID token before the first callable.
    await user.getIdToken();
    try {
      return await _readChatPreviews();
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'unauthenticated') rethrow;
      await user.getIdToken(true);
      return _readChatPreviews();
    }
  }

  Future<List<ChatPreviewModel>> getChatPreviews() async {
    final uid = _auth.currentUser?.uid;
    Object? callableError;
    StackTrace? callableStackTrace;

    try {
      final result = await _readChatPreviewsWithAuthRetry();
      final chats = _dedupeChatPreviews(_parseChatPreviews(result.data));
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
        final chats = _dedupeChatPreviews(
          await _getChatPreviewsFromFirestore(uid),
        );
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
          _dedupeChatPreviews(memoryChats),
        );
      }

      final cachedChats = await _previewCache.loadChatPreviews(uid);
      if (cachedChats.isNotEmpty) {
        final deduped = _dedupeChatPreviews(cachedChats);
        _memoryChatCache[uid] = List<ChatPreviewModel>.unmodifiable(deduped);
        if (deduped.length != cachedChats.length) {
          await _previewCache.saveChatPreviews(uid, deduped);
        }
        return deduped;
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

  List<ChatPreviewModel> _parseChatPreviews(Map<String, dynamic> payload) {
    final rawChats = payload['chats'];
    if (rawChats is! List) return const <ChatPreviewModel>[];

    final chats = <ChatPreviewModel>[];
    for (final rawChat in rawChats) {
      if (rawChat is! Map) continue;
      final chat = ChatPreviewModel.fromMap(Map<String, dynamic>.from(rawChat));
      if (chat.chatId.isEmpty || chat.otherUserId.isEmpty) continue;
      chats.add(chat);
    }
    _sortChats(chats);
    return chats;
  }

  List<ChatPreviewModel> _dedupeChatPreviews(
    Iterable<ChatPreviewModel> source,
  ) {
    final newestByOtherUser = <String, ChatPreviewModel>{};
    for (final chat in source) {
      if (chat.otherUserId.isEmpty) continue;
      final existing = newestByOtherUser[chat.otherUserId];
      if (existing == null || _isPreferredPreview(chat, existing)) {
        newestByOtherUser[chat.otherUserId] = chat;
      }
    }
    final chats = newestByOtherUser.values.toList(growable: false);
    _sortChats(chats);
    return chats;
  }

  bool _isPreferredPreview(
    ChatPreviewModel candidate,
    ChatPreviewModel existing,
  ) {
    final candidateTime =
        candidate.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final existingTime =
        existing.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final timeComparison = candidateTime.compareTo(existingTime);
    if (timeComparison != 0) return timeComparison > 0;

    final candidateHasMessage = candidate.lastMessage.trim().isNotEmpty;
    final existingHasMessage = existing.lastMessage.trim().isNotEmpty;
    if (candidateHasMessage != existingHasMessage) return candidateHasMessage;

    return candidate.chatId.compareTo(existing.chatId) < 0;
  }

  bool _isAfterClear({
    required Timestamp? messageTime,
    required Timestamp? clearedAt,
  }) {
    if (clearedAt == null) return true;
    if (messageTime == null) return false;
    return messageTime.toDate().isAfter(clearedAt.toDate());
  }

  Future<Map<String, dynamic>?> _latestVisibleMessageForPreview({
    required DocumentReference<Map<String, dynamic>> chatRef,
    required String uid,
    required Timestamp? clearedAt,
  }) async {
    final snapshot = await chatRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    for (final document in snapshot.docs) {
      final data = document.data();
      final deletedFor = data['deletedFor'];
      if (deletedFor is List && deletedFor.whereType<String>().contains(uid)) {
        continue;
      }
      final timestamp = data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : null;
      if (!_isAfterClear(messageTime: timestamp, clearedAt: clearedAt)) {
        continue;
      }
      return <String, dynamic>{'id': document.id, ...data};
    }
    return null;
  }

  String _fallbackPreviewText(Map<String, dynamic> message) {
    final text = message['text'];
    if (text is String && text.trim().isNotEmpty) return text;
    final type = message['type'];
    if (type == 'image') return 'Photo';
    if (type == 'video') return 'Video';
    if (type == 'audio' || type == 'voice') return 'Voice message';
    return 'Message';
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
      final clearStates = data['clearStates'] is Map
          ? Map<String, dynamic>.from(data['clearStates'] as Map)
          : const <String, dynamic>{};
      final currentClearState = clearStates[uid] is Map
          ? Map<String, dynamic>.from(clearStates[uid] as Map)
          : const <String, dynamic>{};
      final clearedAt = currentClearState['clearedAt'] is Timestamp
          ? currentClearState['clearedAt'] as Timestamp
          : null;
      final visibleMessage = await _latestVisibleMessageForPreview(
        chatRef: document.reference,
        uid: uid,
        clearedAt: clearedAt,
      );
      final visibleTimestamp = visibleMessage?['timestamp'] is Timestamp
          ? visibleMessage!['timestamp'] as Timestamp
          : null;
      final isUnsent = visibleMessage?['isUnsent'] == true;

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
          lastMessage: visibleMessage == null
              ? ''
              : isUnsent
              ? 'This message was unsent'
              : _fallbackPreviewText(visibleMessage),
          lastMessageTime: visibleTimestamp?.toDate(),
          messageType: visibleMessage?['type'] is String
              ? visibleMessage!['type'] as String
              : 'text',
          isUnsent: isUnsent,
          lastMessageSenderId: visibleMessage?['senderId'] is String
              ? visibleMessage!['senderId'] as String
              : null,
          unreadCount: visibleMessage == null
              ? 0
              : unreadCounts[uid] is num
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
    final deduped = _dedupeChatPreviews(chats);
    final immutable = List<ChatPreviewModel>.unmodifiable(deduped);
    _memoryChatCache[uid] = immutable;
    await _previewCache.saveChatPreviews(uid, immutable);
  }

  void _sortChats(List<ChatPreviewModel> chats) {
    chats.sort((first, second) {
      final firstTime =
          first.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondTime =
          second.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeComparison = secondTime.compareTo(firstTime);
      if (timeComparison != 0) return timeComparison;
      return first.chatId.compareTo(second.chatId);
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
