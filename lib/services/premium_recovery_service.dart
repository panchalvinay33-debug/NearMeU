import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/local_stored_message.dart';
import '../models/message_model.dart';
import 'local_chat_store.dart';

class PremiumRecoveryService {
  PremiumRecoveryService({
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
    LocalChatStore? localChatStore,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _storage = storage ?? FirebaseStorage.instance,
       _localChatStore = localChatStore ?? LocalChatStore();

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final LocalChatStore _localChatStore;

  static const int _pageSize = 100;

  Future<int> restoreChat({
    required String ownerUid,
    required String chatId,
  }) async {
    if (ownerUid.trim().isEmpty || chatId.trim().isEmpty) return 0;

    final existing = await _localChatStore.loadMessages(
      ownerUid: ownerUid,
      chatId: chatId,
      limit: 2000,
    );
    final existingIds = existing
        .map((record) => record.message.id)
        .toSet();

    var restored = 0;
    int? afterMillis;
    while (true) {
      final response = await _functions
          .httpsCallable('getMyPremiumRecoveryPage')
          .call<dynamic>(<String, Object>{
            'chatId': chatId,
            'limit': _pageSize,
            if (afterMillis != null) 'afterMillis': afterMillis,
          });
      final data = response.data;
      if (data is! Map) return restored;
      final rawMessages = data['messages'];
      if (rawMessages is! List || rawMessages.isEmpty) return restored;

      final records = <LocalStoredMessage>[];
      int? lastTimestampMillis;
      for (final raw in rawMessages) {
        if (raw is! Map) continue;
        final messageId = raw['messageId'];
        final senderId = raw['senderId'];
        final receiverId = raw['receiverId'];
        final timestampMillis = raw['timestampMillis'];
        if (messageId is! String ||
            messageId.isEmpty ||
            senderId is! String ||
            senderId.isEmpty ||
            receiverId is! String ||
            receiverId.isEmpty ||
            timestampMillis is! num) {
          continue;
        }
        lastTimestampMillis = timestampMillis.toInt();
        if (existingIds.contains(messageId)) continue;

        final type = raw['type'] is String ? raw['type'] as String : 'text';
        final recoveryMediaPath = raw['recoveryMediaStoragePath'] is String
            ? raw['recoveryMediaStoragePath'] as String
            : null;
        String? localMediaPath;
        if (type != 'text' &&
            recoveryMediaPath != null &&
            recoveryMediaPath.isNotEmpty) {
          localMediaPath = await _downloadRecoveryMedia(
            ownerUid: ownerUid,
            chatId: chatId,
            messageId: messageId,
            recoveryStoragePath: recoveryMediaPath,
          );
        }

        final message = MessageModel(
          id: messageId,
          senderId: senderId,
          receiverId: receiverId,
          text: raw['text'] is String ? raw['text'] as String : '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            timestampMillis.toInt(),
          ),
          replyToMessageId: raw['replyToMessageId'] is String
              ? raw['replyToMessageId'] as String
              : null,
          replyToText: raw['replyToText'] is String
              ? raw['replyToText'] as String
              : null,
          replyToSenderId: raw['replyToSenderId'] is String
              ? raw['replyToSenderId'] as String
              : null,
          type: type,
          mediaContentType: raw['mediaContentType'] is String
              ? raw['mediaContentType'] as String
              : null,
          mediaSizeBytes: raw['mediaSizeBytes'] is num
              ? (raw['mediaSizeBytes'] as num).toInt()
              : null,
          mediaDurationMs: raw['mediaDurationMs'] is num
              ? (raw['mediaDurationMs'] as num).toInt()
              : null,
          localMediaPath: localMediaPath,
        );
        records.add(
          LocalStoredMessage(
            chatId: chatId,
            message: message,
            localMediaPath: localMediaPath,
            downloadComplete: type == 'text' || localMediaPath != null,
            cloudMediaDeleted: false,
            pendingUpload: false,
          ),
        );
        existingIds.add(messageId);
      }

      if (records.isNotEmpty) {
        await _localChatStore.upsertMessages(
          ownerUid: ownerUid,
          records: records,
        );
        restored += records.length;
      }

      final hasMore = data['hasMore'] == true;
      if (!hasMore || lastTimestampMillis == null) return restored;
      if (afterMillis != null && lastTimestampMillis <= afterMillis) {
        return restored;
      }
      afterMillis = lastTimestampMillis;
    }
  }

  Future<String> _downloadRecoveryMedia({
    required String ownerUid,
    required String chatId,
    required String messageId,
    required String recoveryStoragePath,
  }) async {
    final support = await getApplicationSupportDirectory();
    final fileName = p.basename(recoveryStoragePath);
    if (fileName.isEmpty) {
      throw StateError('Recovery media path has no file name.');
    }
    final directory = Directory(
      p.join(
        support.path,
        'premium_recovered_media',
        _safeSegment(ownerUid),
        _safeSegment(chatId),
        _safeSegment(messageId),
      ),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final destination = File(p.join(directory.path, fileName));
    if (await destination.exists() && await destination.length() > 0) {
      return destination.path;
    }
    await _storage.ref(recoveryStoragePath).writeToFile(destination);
    return destination.path;
  }

  String _safeSegment(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}
