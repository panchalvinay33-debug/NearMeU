import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Keeps private-message delivery receipts independent from the chat screen.
///
/// A message becomes delivered only after the receiver's authenticated app has
/// actually observed it from Firestore. Read receipts remain a separate action
/// performed when the receiver opens the conversation.
class MessageDeliveryLifecycle extends StatefulWidget {
  const MessageDeliveryLifecycle({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<MessageDeliveryLifecycle> createState() =>
      _MessageDeliveryLifecycleState();
}

class _MessageDeliveryLifecycleState extends State<MessageDeliveryLifecycle> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSubscription;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _messageSubscriptions =
      <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
  final Set<String> _pendingReceiptKeys = <String>{};
  String? _activeUid;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChanged,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Delivery receipt auth listener failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> _handleAuthChanged(User? user) async {
    await _stopChatListeners();
    _activeUid = user?.uid;
    if (user == null) return;

    _chatSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen(
          (snapshot) => _syncChatListeners(user.uid, snapshot.docs),
          onError: (Object error, StackTrace stackTrace) {
            developer.log(
              'Delivery receipt chat listener failed',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  Future<void> _syncChatListeners(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  ) async {
    if (_activeUid != uid) return;

    final visibleChats = chats.take(50).toList(growable: false);
    final activeChatIds = visibleChats.map((doc) => doc.id).toSet();
    final obsoleteChatIds = _messageSubscriptions.keys
        .where((chatId) => !activeChatIds.contains(chatId))
        .toList(growable: false);

    for (final chatId in obsoleteChatIds) {
      await _messageSubscriptions.remove(chatId)?.cancel();
    }

    for (final chat in visibleChats) {
      if (_messageSubscriptions.containsKey(chat.id)) continue;
      final participants = chat.data()['participants'];
      if (participants is! List) continue;
      final otherUserId = participants.whereType<String>().firstWhere(
        (participant) => participant != uid,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) continue;

      _messageSubscriptions[chat.id] = chat.reference
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .listen(
            (snapshot) => _acknowledgeDelivered(
              uid: uid,
              otherUserId: otherUserId,
              chatId: chat.id,
              messages: snapshot.docs,
            ),
            onError: (Object error, StackTrace stackTrace) {
              developer.log(
                'Delivery receipt message listener failed',
                error: error,
                stackTrace: stackTrace,
              );
            },
          );
    }
  }

  Future<void> _acknowledgeDelivered({
    required String uid,
    required String otherUserId,
    required String chatId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  }) async {
    if (_activeUid != uid) return;

    final messageIds = messages
        .where((message) {
          final data = message.data();
          return data['receiverId'] == uid &&
              data['senderId'] == otherUserId &&
              data['isDelivered'] != true;
        })
        .map((message) => message.id)
        .take(100)
        .toList(growable: false);
    if (messageIds.isEmpty) return;

    final receiptKey = '$chatId|${messageIds.join(',')}';
    if (!_pendingReceiptKeys.add(receiptKey)) return;

    try {
      await _functions
          .httpsCallable('acknowledgePrivateMessagesDelivered')
          .call<void>(<String, Object>{
            'otherUserId': otherUserId,
            'messageIds': messageIds,
          });
    } on FirebaseFunctionsException catch (error, stackTrace) {
      developer.log(
        'Could not acknowledge delivered messages (${error.code})',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _pendingReceiptKeys.remove(receiptKey);
    }
  }

  Future<void> _stopChatListeners() async {
    await _chatSubscription?.cancel();
    _chatSubscription = null;
    final subscriptions = _messageSubscriptions.values.toList(growable: false);
    _messageSubscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    _pendingReceiptKeys.clear();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_stopChatListeners());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
