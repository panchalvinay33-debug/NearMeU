import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_user.dart';
import '../models/chat_preview_model.dart';
import '../models/message_model.dart';
import '../security/chat_security.dart';
import '../security/suspension_service.dart';
import 'local_chat_store.dart';
import 'user_service.dart';

class ChatService {
  ChatService({ChatSecurity? chatSecurity, LocalChatStore? localChatStore})
    : _chatSecurity = chatSecurity ?? ChatSecurity(),
      _localChatStore = localChatStore ?? LocalChatStore();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );
  final ChatSecurity _chatSecurity;
  final LocalChatStore _localChatStore;
  final UserService _userService = UserService();
  final Set<String> _pendingMessageKeys = <String>{};
  final SuspensionService _suspensionService = SuspensionService();

  String getChatId(String user1, String user2) {
    return _chatSecurity.chatIdFor(user1, user2);
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    MessageModel? replyTo,
  }) async {
    final safeText = _chatSecurity.validateOutgoingMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
    );

    await _suspensionService.ensureUserAllowed(senderId);

    final isBlocked = await _userService.isBlockedEitherWay(
      currentUserId: senderId,
      otherUserId: receiverId,
    );
    if (isBlocked) throw Exception('blocked');

    final pendingKey = '$senderId|$receiverId|$safeText';
    if (!_pendingMessageKeys.add(pendingKey)) {
      throw const ChatSecurityException('Message is already sending.');
    }

    try {
      await _functions.httpsCallable('sendPrivateMessage').call<void>(
        <String, dynamic>{
          'receiverId': receiverId,
          'text': safeText,
          'replyTo': replyTo == null
              ? null
              : <String, dynamic>{
                  'messageId': replyTo.id,
                  'text': replyTo.text,
                  'senderId': replyTo.senderId,
                },
        },
      );
      _chatSecurity.recordMessageSent(senderId);
    } on FirebaseFunctionsException catch (error) {
      throw ChatSecurityException(_functionsErrorMessage(error));
    } finally {
      _pendingMessageKeys.remove(pendingKey);
    }
  }

  String _functionsErrorMessage(FirebaseFunctionsException error) {
    final serverMessage = error.message?.trim();
    if (serverMessage != null && serverMessage.isNotEmpty) return serverMessage;

    switch (error.code) {
      case 'resource-exhausted':
        return 'Please slow down before sending more messages.';
      case 'permission-denied':
        return 'Messaging is unavailable for this chat.';
      case 'failed-precondition':
        return 'This chat is not available right now.';
      case 'unauthenticated':
        return 'Please sign in again.';
      default:
        return 'Unable to complete this chat action. Please try again.';
    }
  }

  bool _isTransientFirestoreError(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'cancelled' ||
        error.code == 'unknown';
  }

  Future<void> unsendMessage({
    required String currentUserId,
    required String otherUserId,
    required MessageModel message,
  }) async {
    await _suspensionService.ensureUserAllowed(currentUserId);
    if (!message.canUnsend(currentUserId)) return;

    final chatId = getChatId(currentUserId, otherUserId);
    final unsentAt = DateTime.now();

    try {
      await _functions.httpsCallable('unsendPrivateMessage').call<void>(
        <String, dynamic>{'otherUserId': otherUserId, 'messageId': message.id},
      );
    } on FirebaseFunctionsException catch (error) {
      throw ChatSecurityException(_functionsErrorMessage(error));
    }

    try {
      await _localChatStore.markMessageUnsent(
        ownerUid: currentUserId,
        chatId: chatId,
        messageId: message.id,
        unsentAt: unsentAt,
      );
      await _deleteLocalMediaFile(message.localMediaPath);
      await _deleteLocalMediaFile(message.localThumbnailPath);
    } catch (error, stackTrace) {
      developer.log(
        'Local unsend cleanup deferred',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _deleteLocalMediaFile(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error, stackTrace) {
      developer.log(
        'Could not remove local unsent media immediately',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteMessageForMe({
    required String currentUserId,
    required String otherUserId,
    required MessageModel message,
  }) async {
    await _suspensionService.ensureUserAllowed(currentUserId);

    final chatId = getChatId(currentUserId, otherUserId);
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);

    await messageRef.set(<String, Object?>{
      'deletedFor': FieldValue.arrayUnion(<String>[currentUserId]),
    }, SetOptions(merge: true));

    try {
      await _localChatStore.deleteMessageForOwner(
        ownerUid: currentUserId,
        chatId: chatId,
        messageId: message.id,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Local delete-for-me update deferred',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> markChatAsRead({
    required String currentUserId,
    required String otherUserId,
    String? lastReadMessageId,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);
    final updateData = <Object, Object?>{
      FieldPath(<String>['unreadCounts', currentUserId]): 0,
      FieldPath(<String>['readStates', currentUserId, 'unreadCount']): 0,
      FieldPath(<String>['readStates', currentUserId, 'lastReadAt']):
          FieldValue.serverTimestamp(),
      if (lastReadMessageId != null)
        FieldPath(<String>['readStates', currentUserId, 'lastReadMessageId']):
            lastReadMessageId,
    };

    try {
      await _firestore.collection('chats').doc(chatId).update(updateData);
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') rethrow;
    }
  }

  Future<void> markMessagesAsSeen({
    required String currentUserId,
    required String otherUserId,
  }) async {
    await _suspensionService.ensureUserAllowed(currentUserId);

    final chatId = getChatId(currentUserId, otherUserId);
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isSeen', isEqualTo: false)
        .get();

    await markChatAsRead(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
    if (snapshot.docs.isEmpty) return;

    const batchSize = 400;
    for (var start = 0; start < snapshot.docs.length; start += batchSize) {
      final end = start + batchSize < snapshot.docs.length
          ? start + batchSize
          : snapshot.docs.length;
      final batch = _firestore.batch();

      for (final messageDoc in snapshot.docs.sublist(start, end)) {
        batch.update(messageDoc.reference, <String, Object?>{
          'isSeen': true,
          'seenAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Stream<List<MessageModel>> getMessages({
    required String user1,
    required String user2,
  }) async* {
    await _suspensionService.ensureUserAllowed(user1);
    final chatId = getChatId(user1, user2);
    var hasUsableLocalHistory = false;

    try {
      await _localChatStore.clearExpiredRemoteReferences(ownerUid: user1);
      final localMessages = await _localChatStore.loadVisibleMessages(
        ownerUid: user1,
        chatId: chatId,
      );
      hasUsableLocalHistory = localMessages.isNotEmpty;
      if (hasUsableLocalHistory) yield localMessages;
    } catch (error, stackTrace) {
      developer.log(
        'Encrypted local chat history is unavailable; using cloud only',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final remoteStream = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .snapshots(includeMetadataChanges: false);

      await for (final snapshot in remoteStream) {
        final remoteMessages = _messagesFromSnapshot(
          snapshot: snapshot,
          ownerUid: user1,
        );

        try {
          await _localChatStore.saveRemoteMessages(
            ownerUid: user1,
            chatId: chatId,
            messages: remoteMessages,
          );
          await _localChatStore.clearExpiredRemoteReferences(ownerUid: user1);
          final mergedMessages = await _localChatStore.loadVisibleMessages(
            ownerUid: user1,
            chatId: chatId,
          );
          hasUsableLocalHistory = mergedMessages.isNotEmpty;
          yield mergedMessages;
        } catch (error, stackTrace) {
          developer.log(
            'Could not persist the latest cloud messages locally',
            error: error,
            stackTrace: stackTrace,
          );
          hasUsableLocalHistory = remoteMessages.isNotEmpty;
          yield remoteMessages;
        }
      }
    } on FirebaseException catch (error, stackTrace) {
      if (!hasUsableLocalHistory) rethrow;
      developer.log(
        'Cloud chat stream unavailable; encrypted local history remains visible',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      if (!hasUsableLocalHistory) rethrow;
      developer.log(
        'Cloud chat stream ended; encrypted local history remains visible',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<MessageModel> _messagesFromSnapshot({
    required QuerySnapshot<Map<String, dynamic>> snapshot,
    required String ownerUid,
  }) {
    final latestMessages = <MessageModel>[];
    for (final document in snapshot.docs) {
      try {
        final message = MessageModel.fromMap(document.id, document.data());
        if (!message.deletedFor.contains(ownerUid)) {
          latestMessages.add(message);
        }
      } catch (error, stackTrace) {
        developer.log(
          'Skipping malformed legacy message',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return latestMessages.reversed.toList(growable: false);
  }

  Stream<List<ChatPreviewModel>> getChatsForUser(String currentUserId) async* {
    await _suspensionService.ensureUserAllowed(currentUserId);

    yield* _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots(includeMetadataChanges: false)
        .asyncMap((snapshot) async {
          final chats = <ChatPreviewModel>[];

          for (final document in snapshot.docs) {
            try {
              final data = document.data();
              final rawParticipants = data['participants'];
              if (rawParticipants is! List) continue;

              final participants = rawParticipants.whereType<String>().toList();
              if (participants.length != 2 ||
                  !participants.contains(currentUserId)) {
                continue;
              }

              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              if (otherUserId.isEmpty) continue;

              var isBlocked = false;
              try {
                isBlocked = await _userService.isBlockedEitherWay(
                  currentUserId: currentUserId,
                  otherUserId: otherUserId,
                );
              } on FirebaseException catch (error, stackTrace) {
                if (!_isTransientFirestoreError(error)) {
                  developer.log(
                    'Skipping chat because block status is unavailable',
                    error: error,
                    stackTrace: stackTrace,
                  );
                  continue;
                }
              }
              if (isBlocked) continue;

              AppUser? otherUser;
              try {
                otherUser = await _userService.getUser(otherUserId);
              } catch (error, stackTrace) {
                developer.log(
                  'Unable to read chat participant public profile',
                  error: error,
                  stackTrace: stackTrace,
                );
              }

              final unreadCounts = data['unreadCounts'] is Map
                  ? Map<String, dynamic>.from(data['unreadCounts'] as Map)
                  : <String, dynamic>{};
              final readStates = data['readStates'] is Map
                  ? Map<String, dynamic>.from(data['readStates'] as Map)
                  : <String, dynamic>{};
              final currentReadState = readStates[currentUserId] is Map
                  ? Map<String, dynamic>.from(readStates[currentUserId] as Map)
                  : <String, dynamic>{};

              var unreadCount = unreadCounts[currentUserId] is int
                  ? unreadCounts[currentUserId] as int
                  : currentReadState['unreadCount'] is int
                  ? currentReadState['unreadCount'] as int
                  : 0;
              bool? lastMessageSeen;
              var messageType = data['lastMessageType'] is String
                  ? data['lastMessageType'] as String
                  : 'text';
              var isUnsent =
                  data['lastMessageIsUnsent'] == true ||
                  data['lastMessage'] == 'This message was unsent';

              try {
                final latestMessage = await document.reference
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();
                if (latestMessage.docs.isNotEmpty) {
                  final messageData = latestMessage.docs.first.data();
                  if (messageData['type'] is String) {
                    messageType = messageData['type'] as String;
                  }
                  isUnsent = messageData['isUnsent'] == true || isUnsent;
                  lastMessageSeen = messageData['isSeen'] is bool
                      ? messageData['isSeen'] as bool
                      : null;
                }

                if (unreadCount == 0 && !data.containsKey('unreadCounts')) {
                  final unreadSnapshot = await document.reference
                      .collection('messages')
                      .where('receiverId', isEqualTo: currentUserId)
                      .where('isSeen', isEqualTo: false)
                      .limit(100)
                      .get();
                  unreadCount = unreadSnapshot.size;
                }
              } catch (error, stackTrace) {
                developer.log(
                  'Unable to hydrate chat preview metadata',
                  error: error,
                  stackTrace: stackTrace,
                );
              }

              chats.add(
                ChatPreviewModel(
                  chatId: document.id,
                  otherUserId: otherUserId,
                  otherUserName: otherUser?.nickname.isNotEmpty == true
                      ? otherUser!.nickname
                      : 'Unavailable user',
                  otherUserPhotoUrl: otherUser?.photoUrl,
                  lastMessage: data['lastMessage'] is String
                      ? data['lastMessage'] as String
                      : '',
                  lastMessageTime: data['lastMessageTime'] is Timestamp
                      ? (data['lastMessageTime'] as Timestamp).toDate()
                      : null,
                  messageType: messageType,
                  isUnsent: isUnsent,
                  lastMessageSenderId: data['lastMessageSenderId'] is String
                      ? data['lastMessageSenderId'] as String
                      : null,
                  lastMessageSeen: lastMessageSeen,
                  unreadCount: unreadCount,
                  isOtherUserOnline: otherUser?.isOnline,
                ),
              );
            } catch (error, stackTrace) {
              developer.log(
                'Skipping malformed legacy chat preview',
                error: error,
                stackTrace: stackTrace,
              );
            }
          }

          chats.sort((first, second) {
            final firstTime =
                first.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final secondTime =
                second.lastMessageTime ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final byTime = secondTime.compareTo(firstTime);
            return byTime != 0 ? byTime : first.chatId.compareTo(second.chatId);
          });
          return chats;
        });
  }

  Stream<int> watchPrivateUnreadCount(String currentUserId) {
    return getChatsForUser(currentUserId).map(
      (chats) => chats.fold<int>(0, (total, chat) => total + chat.unreadCount),
    );
  }

  Future<void> deleteCurrentUserChats(String uid) async {
    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();

    const batchSize = 400;
    for (final chat in chats.docs) {
      final messages = await chat.reference.collection('messages').get();
      final visibleMessages = messages.docs.where((message) {
        final deletedFor = List<String>.from(
          message.data()['deletedFor'] ?? <String>[],
        );
        return !deletedFor.contains(uid);
      }).toList();

      for (var start = 0; start < visibleMessages.length; start += batchSize) {
        final end = start + batchSize < visibleMessages.length
            ? start + batchSize
            : visibleMessages.length;
        final batch = _firestore.batch();
        for (final message in visibleMessages.sublist(start, end)) {
          batch.update(message.reference, <String, Object?>{
            'deletedFor': FieldValue.arrayUnion(<String>[uid]),
          });
        }
        await batch.commit();
      }
    }

    await _localChatStore.clearAccount(uid);
  }
}
