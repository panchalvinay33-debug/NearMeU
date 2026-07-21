import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/chat_preview_model.dart';
import '../models/message_model.dart';
import 'user_service.dart';
import '../security/chat_security.dart';
import '../security/suspension_service.dart';

class ChatService {
  ChatService({ChatSecurity? chatSecurity})
      : _chatSecurity = chatSecurity ?? ChatSecurity();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatSecurity _chatSecurity;
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

    if (isBlocked) {
      throw Exception('blocked');
    }

    final chatId = getChatId(senderId, receiverId);
    final participants = <String>[senderId, receiverId]..sort();
    final pendingKey = '$senderId|$receiverId|$safeText';

    if (!_pendingMessageKeys.add(pendingKey)) {
      throw const ChatSecurityException('Message is already sending.');
    }

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': safeText,
      'timestamp': FieldValue.serverTimestamp(),
      'isUnsent': false,
      'unsentAt': null,
      'replyToMessageId': replyTo?.id,
      'replyToText': replyTo?.text,
      'replyToSenderId': replyTo?.senderId,
      'type': 'text',
      'mediaUrl': null,
      'isSeen': false,
      'seenAt': null,
      'deletedFor': <String>[],
    };

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final chatSnapshot = await transaction.get(chatRef);
        final existingUnread = chatSnapshot.exists
            ? Map<String, dynamic>.from(
                chatSnapshot.data()?['unreadCounts'] ?? <String, dynamic>{},
              )
            : <String, dynamic>{};
        final receiverUnread = existingUnread[receiverId] is int
            ? existingUnread[receiverId] as int
            : 0;
        final nextReceiverUnread = receiverUnread + 1;

        if (chatSnapshot.exists) {
          final existingParticipants = List<String>.from(
            chatSnapshot.data()?['participants'] ?? <String>[],
          );
          existingParticipants.sort();
          if (existingParticipants.length != participants.length ||
              existingParticipants.first != participants.first ||
              existingParticipants.last != participants.last) {
            throw const ChatSecurityException('Invalid chat room.');
          }

          transaction.update(chatRef, <Object, Object?>{
            'lastMessage': safeText,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'latestMessageAt': FieldValue.serverTimestamp(),
            'lastMessageSenderId': senderId,
            'latestSenderId': senderId,
            'lastMessageType': 'text',
            'lastMessageIsUnsent': false,
            FieldPath(<String>['unreadCounts', senderId]): 0,
            FieldPath(<String>['unreadCounts', receiverId]): nextReceiverUnread,
            FieldPath(<String>['readStates', senderId, 'lastReadAt']):
                FieldValue.serverTimestamp(),
            FieldPath(<String>['readStates', senderId, 'lastReadMessageId']):
                messageRef.id,
            FieldPath(<String>['readStates', senderId, 'unreadCount']): 0,
            FieldPath(<String>['readStates', receiverId, 'unreadCount']):
                nextReceiverUnread,
          });
        } else {
          transaction.set(chatRef, <String, dynamic>{
            'participants': participants,
            'lastMessage': safeText,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'latestMessageAt': FieldValue.serverTimestamp(),
            'lastMessageSenderId': senderId,
            'latestSenderId': senderId,
            'lastMessageType': 'text',
            'lastMessageIsUnsent': false,
            'createdAt': FieldValue.serverTimestamp(),
            'unreadCounts': <String, dynamic>{
              senderId: 0,
              receiverId: nextReceiverUnread,
            },
            'readStates': <String, dynamic>{
              senderId: <String, dynamic>{
                'lastReadAt': FieldValue.serverTimestamp(),
                'lastReadMessageId': messageRef.id,
                'unreadCount': 0,
              },
              receiverId: <String, dynamic>{
                'unreadCount': nextReceiverUnread,
              },
            },
          });
        }

        transaction.set(messageRef, messageData);
      });
      _chatSecurity.recordMessageSent(senderId);
    } finally {
      _pendingMessageKeys.remove(pendingKey);
    }
  }

  Future<void> unsendMessage({
    required String currentUserId,
    required String otherUserId,
    required MessageModel message,
  }) async {
    await _suspensionService.ensureUserAllowed(currentUserId);

    if (!message.canUnsend(currentUserId)) return;

    final chatId = getChatId(currentUserId, otherUserId);

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);

    await messageRef.update({
      'text': '',
      'isUnsent': true,
      'unsentAt': FieldValue.serverTimestamp(),
      'replyToMessageId': null,
      'replyToText': null,
      'replyToSenderId': null,
      'type': 'text',
      'mediaUrl': null,
    });

    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messagesSnapshot.docs.isNotEmpty &&
        messagesSnapshot.docs.first.id == message.id) {
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': 'This message was unsent',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
       }, SetOptions(merge: true));
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

    await messageRef.set({
      'deletedFor': FieldValue.arrayUnion([currentUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> markChatAsRead({
    required String currentUserId,
    required String otherUserId,
    String? lastReadMessageId,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);
    await _firestore.collection('chats').doc(chatId).update(<Object, Object?>{
      FieldPath(<String>['unreadCounts', currentUserId]): 0,
      FieldPath(<String>['readStates', currentUserId, 'unreadCount']): 0,
      FieldPath(<String>['readStates', currentUserId, 'lastReadAt']):
          FieldValue.serverTimestamp(),
      if (lastReadMessageId != null)
        FieldPath(<String>['readStates', currentUserId, 'lastReadMessageId']):
            lastReadMessageId,
    });
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

    await markChatAsRead(currentUserId: currentUserId, otherUserId: otherUserId);

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isSeen': true,
        'seenAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<List<MessageModel>> getMessages({
    required String user1,
    required String user2,
  }) async* {
    await _suspensionService.ensureUserAllowed(user1);

    final chatId = getChatId(user1, user2);

    yield* _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(200)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      final allMessages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
          .toList();

      return allMessages
          .where((m) => !m.deletedFor.contains(user1))
          .toList();
    });
  }

  Stream<List<ChatPreviewModel>> getChatsForUser(String currentUserId) async* {
    await _suspensionService.ensureUserAllowed(currentUserId);

    yield* _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots(includeMetadataChanges: false)
        .asyncMap((snapshot) async {
      final List<ChatPreviewModel> chats = [];

      final currentUser = await _userService.getUser(currentUserId);

      if (currentUser == null) return chats;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final participants =
            List<String>.from(data['participants'] ?? []);

        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        final userDoc =
            await _firestore.collection('users').doc(otherUserId).get();

        AppUser? otherUser;
        if (userDoc.exists && userDoc.data() != null) {
          otherUser = AppUser.fromMap(userDoc.data()!, userDoc.id);
        }

        if (otherUser != null &&
            _userService.areUsersBlockedEitherWay(
              currentUser: currentUser,
              otherUser: otherUser,
            )) {
          continue;
        }

        final unreadCounts = Map<String, dynamic>.from(
          data['unreadCounts'] ?? <String, dynamic>{},
        );
        final readStates = Map<String, dynamic>.from(
          data['readStates'] ?? <String, dynamic>{},
        );
        final currentReadState = readStates[currentUserId] is Map
            ? Map<String, dynamic>.from(readStates[currentUserId] as Map)
            : <String, dynamic>{};
        var unreadCount = unreadCounts[currentUserId] is int
            ? unreadCounts[currentUserId] as int
            : (currentReadState['unreadCount'] is int
                ? currentReadState['unreadCount'] as int
                : 0);
        bool? lastMessageSeen;
        String messageType = (data['lastMessageType'] as String?) ?? 'text';
        bool isUnsent = data['lastMessageIsUnsent'] == true ||
            data['lastMessage'] == 'This message was unsent';

        try {
          final latestMessage = await doc.reference
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
          if (latestMessage.docs.isNotEmpty) {
            final messageData = latestMessage.docs.first.data();
            messageType = (messageData['type'] as String?) ?? messageType;
            isUnsent = messageData['isUnsent'] == true || isUnsent;
            lastMessageSeen = messageData['isSeen'] as bool?;
          }

          if (unreadCount == 0 && !data.containsKey('unreadCounts')) {
            final unreadSnapshot = await doc.reference
                .collection('messages')
                .where('receiverId', isEqualTo: currentUserId)
                .where('isSeen', isEqualTo: false)
                .limit(100)
                .get();
            unreadCount = unreadSnapshot.size;
          }
        } catch (error) {
          developer.log('Unable to hydrate chat preview metadata', error: error);
        }

        chats.add(
          ChatPreviewModel(
            chatId: doc.id,
            otherUserId: otherUserId,
            otherUserName: otherUser?.nickname.isNotEmpty == true
                ? otherUser!.nickname
                : 'Unavailable user',
            lastMessage: (data['lastMessage'] as String?) ?? '',
            lastMessageTime: data['lastMessageTime'] is Timestamp
                ? (data['lastMessageTime'] as Timestamp).toDate()
                : null,
            messageType: messageType,
            isUnsent: isUnsent,
            lastMessageSenderId: data['lastMessageSenderId'] as String?,
            lastMessageSeen: lastMessageSeen,
            unreadCount: unreadCount,
            isOtherUserOnline: otherUser?.isOnline,
          ),
        );
      }

      chats.sort((a, b) {
        final aTime = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final byTime = bTime.compareTo(aTime);
        return byTime != 0 ? byTime : a.chatId.compareTo(b.chatId);
      });
      return chats;
    });
  }

  Stream<int> watchPrivateUnreadCount(String currentUserId) {
    return getChatsForUser(currentUserId).map(
      (chats) => chats.fold<int>(0, (total, chat) => total + chat.unreadCount),
    );
  }

  /// Deletes every chat (and all messages) that the user participates in.
  Future<void> deleteCurrentUserChats(String uid) async {
    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();

    for (final chat in chats.docs) {
      final messages =
          await chat.reference.collection('messages').get();

      final batch = _firestore.batch();

      for (final message in messages.docs) {
        batch.delete(message.reference);
      }

      batch.delete(chat.reference);

      await batch.commit();
    }
  }  
}
