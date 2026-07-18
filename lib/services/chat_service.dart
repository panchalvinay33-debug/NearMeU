import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/chat_preview_model.dart';
import '../models/message_model.dart';
import 'user_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  String getChatId(String user1, String user2) {
    final ids = [user1, user2]..sort();
    return ids.join('_');
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    MessageModel? replyTo,
  }) async {
    final isBlocked = await _userService.isBlockedEitherWay(
      currentUserId: senderId,
      otherUserId: receiverId,
    );

    if (isBlocked) {
      throw Exception('blocked');
    }

    final chatId = getChatId(senderId, receiverId);

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
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

    final chatData = {
      'participants': [senderId, receiverId],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('chats').doc(chatId).set(
          chatData,
          SetOptions(merge: true),
        );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);
  }

  Future<void> unsendMessage({
    required String currentUserId,
    required String otherUserId,
    required MessageModel message,
  }) async {
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
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteMessageForMe({
    required String currentUserId,
    required String otherUserId,
    required MessageModel message,
  }) async {
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

  Future<void> markMessagesAsSeen({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);

    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isSeen', isEqualTo: false)
        .get();

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
  }) {
    final chatId = getChatId(user1, user2);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final allMessages = snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.id, doc.data());
      }).toList();

      return allMessages.where((m) => !m.deletedFor.contains(user1)).toList();
    });
  }

  Stream<List<ChatPreviewModel>> getChatsForUser(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<ChatPreviewModel> chats = [];
      final currentUser = await _userService.getUser(currentUserId);

      if (currentUser == null) return chats;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        final userDoc =
            await _firestore.collection('users').doc(otherUserId).get();

        if (!userDoc.exists || userDoc.data() == null) continue;

        final otherUser = AppUser.fromMap(userDoc.data()!, userDoc.id);

        if (_userService.areUsersBlockedEitherWay(
          currentUser: currentUser,
          otherUser: otherUser,
        )) {
          continue;
        }

        chats.add(
          ChatPreviewModel(
            chatId: doc.id,
            otherUserId: otherUserId,
            otherUserName: otherUser.nickname.isNotEmpty
                ? otherUser.nickname
                : 'Unknown',
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime:
                (data['lastMessageTime'] as Timestamp?)?.toDate(),
          ),
        );
      }

      return chats;
    });
  }
}