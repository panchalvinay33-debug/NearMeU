import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/local_stored_message.dart';
import '../models/message_model.dart';
import 'local_chat_store.dart';

class VoiceMessageException implements Exception {
  const VoiceMessageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VoiceMessageService {
  VoiceMessageService({
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    LocalChatStore? localChatStore,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _localChatStore = localChatStore ?? LocalChatStore();

  static const int maximumVoiceBytes = 8 * 1024 * 1024;
  static const Duration maximumVoiceDuration = Duration(minutes: 2);

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final LocalChatStore _localChatStore;

  String chatIdFor(String firstUid, String secondUid) {
    final participants = <String>[firstUid, secondUid]..sort();
    return participants.join('_');
  }

  Future<MessageModel> sendRecordedVoice({
    required String senderId,
    required String receiverId,
    required File sourceFile,
    required int durationMs,
    MessageModel? replyTo,
  }) async {
    if (senderId.isEmpty || receiverId.isEmpty || senderId == receiverId) {
      throw const VoiceMessageException('This private chat is not available.');
    }
    if (!await sourceFile.exists()) {
      throw const VoiceMessageException('The recorded voice file is missing.');
    }
    if (durationMs < 700) {
      throw const VoiceMessageException('Voice message is too short.');
    }
    if (durationMs > maximumVoiceDuration.inMilliseconds) {
      throw const VoiceMessageException(
        'Voice message must be two minutes or shorter.',
      );
    }

    final sizeBytes = await sourceFile.length();
    if (sizeBytes <= 0 || sizeBytes > maximumVoiceBytes) {
      throw const VoiceMessageException(
        'Voice message must be smaller than 8 MB.',
      );
    }

    final chatId = chatIdFor(senderId, receiverId);
    final messageId = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc()
        .id;
    final directory = await _mediaDirectory(
      ownerUid: senderId,
      chatId: chatId,
    );
    final localFile = File(p.join(directory.path, '$messageId.m4a'));
    await sourceFile.copy(localFile.path);

    final storagePath =
        'privateChatMedia/$senderId/$chatId/$messageId/upload.m4a';
    final now = DateTime.now();
    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: '',
      timestamp: now,
      replyToMessageId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSenderId: replyTo?.senderId,
      type: 'voice',
      mediaStoragePath: storagePath,
      mediaContentType: 'audio/mp4',
      mediaSizeBytes: sizeBytes,
      mediaDurationMs: durationMs,
      downloadAcknowledgements: <String, DateTime>{senderId: now},
      cloudExpiresAt: now.add(LocalChatStore.cloudMessageRetention),
      localMediaPath: localFile.path,
    );
    final pending = LocalStoredMessage(
      chatId: chatId,
      message: message,
      localMediaPath: localFile.path,
      cloudExpiresAt: message.cloudExpiresAt,
      downloadComplete: true,
      pendingUpload: true,
    );

    await _localChatStore.upsertMessages(
      ownerUid: senderId,
      records: <LocalStoredMessage>[pending],
    );

    final reference = _storage.ref().child(storagePath);
    try {
      await reference.putFile(
        localFile,
        SettableMetadata(
          contentType: 'audio/mp4',
          cacheControl: 'private,max-age=0,no-store',
          customMetadata: <String, String>{
            'senderId': senderId,
            'receiverId': receiverId,
            'chatId': chatId,
            'messageId': messageId,
            'mediaType': 'voice',
          },
        ),
      );

      await _functions.httpsCallable('sendPrivateMediaMessage').call<void>(
        <String, dynamic>{
          'receiverId': receiverId,
          'messageId': messageId,
          'type': 'voice',
          'storagePath': storagePath,
          'caption': '',
          'durationMs': durationMs,
          'replyTo': replyTo == null
              ? null
              : <String, dynamic>{
                  'messageId': replyTo.id,
                  'text': replyTo.text,
                  'senderId': replyTo.senderId,
                },
        },
      );

      await _localChatStore.upsertMessages(
        ownerUid: senderId,
        records: <LocalStoredMessage>[
          pending.copyWith(pendingUpload: false),
        ],
      );
      return message;
    } on FirebaseFunctionsException catch (error, stackTrace) {
      developer.log(
        'Voice upload confirmation failed; pending outbox retained',
        error: error,
        stackTrace: stackTrace,
      );
      throw VoiceMessageException(
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Voice message is saved and will retry when the chat reconnects.',
      );
    } catch (error) {
      try {
        await reference.delete();
      } catch (_) {}
      await _localChatStore.deleteMessageForOwner(
        ownerUid: senderId,
        chatId: chatId,
        messageId: messageId,
      );
      rethrow;
    } finally {
      if (sourceFile.path != localFile.path) {
        try {
          await sourceFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<String> downloadVoice({
    required String ownerUid,
    required String chatId,
    required MessageModel message,
  }) async {
    if (!message.isVoice) {
      throw const VoiceMessageException('This is not a voice message.');
    }

    final existing = message.localMediaPath;
    if (existing != null && await File(existing).exists()) {
      await _acknowledge(ownerUid: ownerUid, chatId: chatId, message: message);
      return existing;
    }

    final storagePath = message.mediaStoragePath;
    if (storagePath == null || storagePath.isEmpty || !message.hasRemoteMedia) {
      throw const VoiceMessageException(
        'This voice message is no longer available in the cloud.',
      );
    }

    final directory = await _mediaDirectory(ownerUid: ownerUid, chatId: chatId);
    final destination = File(p.join(directory.path, '${message.id}.m4a'));
    final partial = File('${destination.path}.part');
    if (await partial.exists()) await partial.delete();

    try {
      await _storage.ref().child(storagePath).writeToFile(partial);
      final actualBytes = await partial.length();
      if (actualBytes <= 0 ||
          (message.mediaSizeBytes != null &&
              actualBytes != message.mediaSizeBytes)) {
        await partial.delete();
        throw const VoiceMessageException(
          'The downloaded voice message did not pass verification.',
        );
      }
      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);

      final downloaded = message.withLocalMedia(
        localMediaPath: destination.path,
      );
      await _localChatStore.upsertMessages(
        ownerUid: ownerUid,
        records: <LocalStoredMessage>[
          LocalStoredMessage(
            chatId: chatId,
            message: downloaded,
            localMediaPath: destination.path,
            cloudExpiresAt: message.cloudExpiresAt,
            downloadComplete: true,
            cloudMediaDeleted: message.cloudMediaDeletedAt != null,
          ),
        ],
      );
      await _acknowledge(ownerUid: ownerUid, chatId: chatId, message: message);
      return destination.path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  Future<void> _acknowledge({
    required String ownerUid,
    required String chatId,
    required MessageModel message,
  }) async {
    if (message.senderId == ownerUid || message.cloudMediaDeletedAt != null) {
      return;
    }
    try {
      final result = await _functions
          .httpsCallable('acknowledgePrivateMediaDownload')
          .call<Map<String, dynamic>>(<String, dynamic>{
            'chatId': chatId,
            'messageId': message.id,
          });
      final data = Map<String, dynamic>.from(result.data);
      if (data['cloudMediaDeleted'] == true) {
        await _localChatStore.markCloudMediaDeleted(
          ownerUid: ownerUid,
          chatId: chatId,
          messageId: message.id,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Voice download acknowledgement deferred',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Directory> _mediaDirectory({
    required String ownerUid,
    required String chatId,
  }) async {
    final support = await getApplicationSupportDirectory();
    final safeOwner = ownerUid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final safeChat = chatId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final directory = Directory(
      p.join(support.path, 'private_media', safeOwner, safeChat),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
