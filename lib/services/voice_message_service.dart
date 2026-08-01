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

enum _VoiceConfirmation { confirmed, rejected, unknown }

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
    final directory = await _mediaDirectory(ownerUid: senderId, chatId: chatId);
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
    var uploadCompleted = false;
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
      uploadCompleted = true;

      Object? confirmationError;
      final confirmation = await _confirmCloudMessage(
        chatId: chatId,
        message: message,
        onError: (error) => confirmationError = error,
      );

      switch (confirmation) {
        case _VoiceConfirmation.confirmed:
          await _localChatStore.upsertMessages(
            ownerUid: senderId,
            records: <LocalStoredMessage>[
              pending.copyWith(pendingUpload: false),
            ],
          );
          return message;
        case _VoiceConfirmation.rejected:
          await _removeRejectedPending(
            ownerUid: senderId,
            chatId: chatId,
            messageId: messageId,
            reference: reference,
          );
          throw VoiceMessageException(_friendlyError(confirmationError));
        case _VoiceConfirmation.unknown:
          developer.log(
            'Voice confirmation deferred to shared media outbox recovery',
            error: confirmationError,
          );
          throw const VoiceMessageException(
            'Voice message is saved securely and will be confirmed when this chat reconnects.',
          );
      }
    } catch (_) {
      if (!uploadCompleted) {
        await _removeRejectedPending(
          ownerUid: senderId,
          chatId: chatId,
          messageId: messageId,
          reference: reference,
        );
      }
      rethrow;
    } finally {
      if (sourceFile.path != localFile.path) {
        try {
          await sourceFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _removeRejectedPending({
    required String ownerUid,
    required String chatId,
    required String messageId,
    required Reference reference,
  }) async {
    try {
      await reference.delete();
    } catch (_) {}
    await _localChatStore.deleteMessageForOwner(
      ownerUid: ownerUid,
      chatId: chatId,
      messageId: messageId,
    );
  }

  Future<_VoiceConfirmation> _confirmCloudMessage({
    required String chatId,
    required MessageModel message,
    required void Function(Object error) onError,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt += 1) {
      try {
        await _functions.httpsCallable('sendPrivateMediaMessage').call<void>(
          <String, dynamic>{
            'receiverId': message.receiverId,
            'messageId': message.id,
            'type': 'voice',
            'storagePath': message.mediaStoragePath,
            'caption': '',
            'durationMs': message.mediaDurationMs,
            'replyTo': message.hasReply
                ? <String, dynamic>{
                    'messageId': message.replyToMessageId,
                    'text': message.replyToText,
                    'senderId': message.replyToSenderId,
                  }
                : null,
          },
        );
        return _VoiceConfirmation.confirmed;
      } catch (error) {
        lastError = error;
        onError(error);
        if (_isDefinitiveFailure(error)) break;
      }
    }

    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id)
          .get();
      if (snapshot.exists) {
        final data = snapshot.data() ?? const <String, dynamic>{};
        final matches = data['senderId'] == message.senderId &&
            data['receiverId'] == message.receiverId &&
            data['mediaStoragePath'] == message.mediaStoragePath;
        return matches
            ? _VoiceConfirmation.confirmed
            : _VoiceConfirmation.rejected;
      }
      if (lastError != null && _isDefinitiveFailure(lastError)) {
        return _VoiceConfirmation.rejected;
      }
      return _VoiceConfirmation.unknown;
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Could not verify voice message commit',
        error: error,
        stackTrace: stackTrace,
      );
      return _VoiceConfirmation.unknown;
    }
  }

  bool _isDefinitiveFailure(Object error) {
    if (error is! FirebaseFunctionsException) return false;
    return const <String>{
      'invalid-argument',
      'unauthenticated',
      'permission-denied',
      'failed-precondition',
      'resource-exhausted',
      'already-exists',
      'not-found',
    }.contains(error.code);
  }

  String _friendlyError(Object? error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }
    if (error is VoiceMessageException) return error.message;
    return 'Could not send this voice message. Please try again.';
  }

  Future<String> downloadVoice({
    required String ownerUid,
    required String chatId,
    required MessageModel message,
  }) async {
    if (!message.isVoice) {
      throw const VoiceMessageException('This is not a voice message.');
    }

    final declaredPath = message.localMediaPath;
    if (declaredPath != null) {
      final declaredFile = File(declaredPath);
      if (await _isValidLocalFile(declaredFile, message.mediaSizeBytes)) {
        await _persistDownloadedVoice(
          ownerUid: ownerUid,
          chatId: chatId,
          message: message,
          file: declaredFile,
        );
        await _acknowledge(ownerUid: ownerUid, chatId: chatId, message: message);
        return declaredPath;
      }
      await _deleteIfExists(declaredFile);
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
    await _deleteIfExists(partial);

    if (await _isValidLocalFile(destination, message.mediaSizeBytes)) {
      await _persistDownloadedVoice(
        ownerUid: ownerUid,
        chatId: chatId,
        message: message,
        file: destination,
      );
      await _acknowledge(ownerUid: ownerUid, chatId: chatId, message: message);
      return destination.path;
    }
    await _deleteIfExists(destination);

    try {
      await _storage.ref().child(storagePath).writeToFile(partial);
      if (!await _isValidLocalFile(partial, message.mediaSizeBytes)) {
        await _deleteIfExists(partial);
        throw const VoiceMessageException(
          'The downloaded voice message did not pass verification.',
        );
      }
      await partial.rename(destination.path);
      await _persistDownloadedVoice(
        ownerUid: ownerUid,
        chatId: chatId,
        message: message,
        file: destination,
      );
      await _acknowledge(ownerUid: ownerUid, chatId: chatId, message: message);
      return destination.path;
    } catch (_) {
      await _deleteIfExists(partial);
      rethrow;
    }
  }

  Future<bool> _isValidLocalFile(File file, int? expectedBytes) async {
    if (!await file.exists()) return false;
    final actualBytes = await file.length();
    if (actualBytes <= 0 || actualBytes > maximumVoiceBytes) return false;
    return expectedBytes == null || expectedBytes <= 0 || actualBytes == expectedBytes;
  }

  Future<void> _persistDownloadedVoice({
    required String ownerUid,
    required String chatId,
    required MessageModel message,
    required File file,
  }) async {
    final downloaded = message.withLocalMedia(localMediaPath: file.path);
    await _localChatStore.upsertMessages(
      ownerUid: ownerUid,
      records: <LocalStoredMessage>[
        LocalStoredMessage(
          chatId: chatId,
          message: downloaded,
          localMediaPath: file.path,
          cloudExpiresAt: message.cloudExpiresAt,
          downloadComplete: true,
          cloudMediaDeleted: message.cloudMediaDeletedAt != null,
          pendingUpload: false,
        ),
      ],
    );
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
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
