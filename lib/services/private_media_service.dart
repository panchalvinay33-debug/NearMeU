import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../models/local_stored_message.dart';
import '../models/message_model.dart';
import 'local_chat_store.dart';

class PreparedPrivateMedia {
  const PreparedPrivateMedia({
    required this.file,
    required this.type,
    required this.contentType,
    required this.sizeBytes,
    this.durationMs,
  });

  final File file;
  final String type;
  final String contentType;
  final int sizeBytes;
  final int? durationMs;

  bool get isVideo => type == 'video';
}

class PrivateMediaException implements Exception {
  const PrivateMediaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrivateMediaService {
  PrivateMediaService({
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    ImagePicker? picker,
    LocalChatStore? localChatStore,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _picker = picker ?? ImagePicker(),
       _localChatStore = localChatStore ?? LocalChatStore();

  static const int maximumImageBytes = 5 * 1024 * 1024;
  static const int maximumVideoBytes = 30 * 1024 * 1024;
  static const Duration maximumVideoDuration = Duration(minutes: 2);

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final ImagePicker _picker;
  final LocalChatStore _localChatStore;

  String chatIdFor(String firstUid, String secondUid) {
    final participants = <String>[firstUid, secondUid]..sort();
    return participants.join('_');
  }

  Future<PreparedPrivateMedia?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final selected = await _picker.pickImage(source: source);
    if (selected == null) return null;

    final temporaryDirectory = await getTemporaryDirectory();
    final qualities = <int>[82, 68, 54, 40];
    File? latest;
    for (final quality in qualities) {
      final targetPath = p.join(
        temporaryDirectory.path,
        'nearmeu_image_${DateTime.now().microsecondsSinceEpoch}_$quality.jpg',
      );
      final compressed = await FlutterImageCompress.compressAndGetFile(
        selected.path,
        targetPath,
        minWidth: 1600,
        minHeight: 1600,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (compressed == null) continue;
      latest = File(compressed.path);
      final length = await latest.length();
      if (length > 0 && length <= maximumImageBytes) {
        return PreparedPrivateMedia(
          file: latest,
          type: 'image',
          contentType: 'image/jpeg',
          sizeBytes: length,
        );
      }
    }

    try {
      await latest?.delete();
    } catch (_) {}
    throw const PrivateMediaException(
      'This photo is still larger than 5 MB after compression.',
    );
  }

  Future<PreparedPrivateMedia?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    final selected = await _picker.pickVideo(
      source: source,
      maxDuration: maximumVideoDuration,
    );
    if (selected == null) return null;

    final originalInfo = await VideoCompress.getMediaInfo(selected.path);
    final originalDurationMs = originalInfo.duration?.round();
    if (originalDurationMs == null || originalDurationMs <= 0) {
      throw const PrivateMediaException('Could not read this video.');
    }
    if (originalDurationMs > maximumVideoDuration.inMilliseconds) {
      throw const PrivateMediaException(
        'Video must be two minutes or shorter.',
      );
    }

    MediaInfo? compressed = await VideoCompress.compressVideo(
      selected.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );
    var file = compressed?.file;
    if (file == null || !await file.exists()) {
      throw const PrivateMediaException('Could not compress this video.');
    }

    var length = await file.length();
    if (length > maximumVideoBytes) {
      compressed = await VideoCompress.compressVideo(
        selected.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      file = compressed?.file;
      if (file == null || !await file.exists()) {
        throw const PrivateMediaException('Could not compress this video.');
      }
      length = await file.length();
    }

    if (length <= 0 || length > maximumVideoBytes) {
      throw const PrivateMediaException(
        'Compressed video must be smaller than 30 MB.',
      );
    }

    final durationMs = compressed?.duration?.round() ?? originalDurationMs;
    if (durationMs > maximumVideoDuration.inMilliseconds) {
      throw const PrivateMediaException(
        'Video must be two minutes or shorter.',
      );
    }

    return PreparedPrivateMedia(
      file: file,
      type: 'video',
      contentType: 'video/mp4',
      sizeBytes: length,
      durationMs: durationMs,
    );
  }

  Future<MessageModel> sendPreparedMedia({
    required String senderId,
    required String receiverId,
    required PreparedPrivateMedia media,
    String caption = '',
    MessageModel? replyTo,
  }) async {
    if (senderId.isEmpty || receiverId.isEmpty || senderId == receiverId) {
      throw const PrivateMediaException('This private chat is not available.');
    }

    final chatId = chatIdFor(senderId, receiverId);
    final messageId = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc()
        .id;
    final extension = media.isVideo ? 'mp4' : 'jpg';
    final localDirectory = await _mediaDirectory(
      ownerUid: senderId,
      chatId: chatId,
    );
    final localFile = File(p.join(localDirectory.path, '$messageId.$extension'));
    await media.file.copy(localFile.path);

    String? localThumbnailPath;
    if (media.isVideo) {
      final generated = await VideoCompress.getFileThumbnail(
        localFile.path,
        quality: 55,
        position: -1,
      );
      final thumbnail = File(
        p.join(localDirectory.path, '${messageId}_thumbnail.jpg'),
      );
      await generated.copy(thumbnail.path);
      localThumbnailPath = thumbnail.path;
    }

    final storagePath =
        'privateChatMedia/$senderId/$chatId/$messageId/upload.$extension';
    final now = DateTime.now();
    final pendingMessage = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: caption.trim(),
      timestamp: now,
      replyToMessageId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSenderId: replyTo?.senderId,
      type: media.type,
      mediaStoragePath: storagePath,
      mediaContentType: media.contentType,
      mediaSizeBytes: media.sizeBytes,
      mediaDurationMs: media.durationMs,
      downloadAcknowledgements: <String, DateTime>{senderId: now},
      cloudExpiresAt: now.add(LocalChatStore.cloudMessageRetention),
      localMediaPath: localFile.path,
      localThumbnailPath: localThumbnailPath,
    );
    final pendingRecord = LocalStoredMessage(
      chatId: chatId,
      message: pendingMessage,
      localMediaPath: localFile.path,
      localThumbnailPath: localThumbnailPath,
      cloudExpiresAt: pendingMessage.cloudExpiresAt,
      downloadComplete: true,
      pendingUpload: true,
    );
    await _localChatStore.upsertMessages(
      ownerUid: senderId,
      records: <LocalStoredMessage>[pendingRecord],
    );

    final reference = _storage.ref().child(storagePath);
    try {
      await reference.putFile(
        localFile,
        SettableMetadata(
          contentType: media.contentType,
          cacheControl: 'private,max-age=0,no-store',
          customMetadata: <String, String>{
            'senderId': senderId,
            'receiverId': receiverId,
            'chatId': chatId,
            'messageId': messageId,
            'mediaType': media.type,
          },
        ),
      );

      await _functions.httpsCallable('sendPrivateMediaMessage').call<void>(
        <String, dynamic>{
          'receiverId': receiverId,
          'messageId': messageId,
          'type': media.type,
          'storagePath': storagePath,
          'caption': caption.trim(),
          'durationMs': media.durationMs,
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
          pendingRecord.copyWith(pendingUpload: false),
        ],
      );
      return pendingMessage;
    } catch (error) {
      try {
        await reference.delete();
      } catch (_) {}
      await _localChatStore.deleteMessageForOwner(
        ownerUid: senderId,
        chatId: chatId,
        messageId: messageId,
      );
      try {
        await localFile.delete();
        if (localThumbnailPath != null) {
          await File(localThumbnailPath).delete();
        }
      } catch (_) {}
      rethrow;
    } finally {
      if (media.file.path != localFile.path) {
        try {
          await media.file.delete();
        } catch (_) {}
      }
    }
  }

  Future<String> downloadMessageMedia({
    required String ownerUid,
    required String chatId,
    required MessageModel message,
  }) async {
    if (!message.isMedia) {
      throw const PrivateMediaException('This message has no media file.');
    }
    final existingPath = message.localMediaPath;
    if (existingPath != null && await File(existingPath).exists()) {
      await _acknowledgeDownload(
        ownerUid: ownerUid,
        chatId: chatId,
        message: message,
      );
      return existingPath;
    }

    final storagePath = message.mediaStoragePath;
    if (storagePath == null || storagePath.isEmpty || !message.hasRemoteMedia) {
      throw const PrivateMediaException(
        'This media is no longer available in the cloud.',
      );
    }

    final localDirectory = await _mediaDirectory(
      ownerUid: ownerUid,
      chatId: chatId,
    );
    final extension = message.isVideo ? 'mp4' : 'jpg';
    final destination = File(
      p.join(localDirectory.path, '${message.id}.$extension'),
    );
    final partial = File('${destination.path}.part');
    if (await partial.exists()) await partial.delete();

    try {
      await _storage.ref().child(storagePath).writeToFile(partial);
      final actualBytes = await partial.length();
      if (actualBytes <= 0 ||
          (message.mediaSizeBytes != null &&
              actualBytes != message.mediaSizeBytes)) {
        await partial.delete();
        throw const PrivateMediaException(
          'The downloaded file did not pass verification.',
        );
      }
      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);

      String? localThumbnailPath;
      if (message.isVideo) {
        final generated = await VideoCompress.getFileThumbnail(
          destination.path,
          quality: 55,
          position: -1,
        );
        final thumbnail = File(
          p.join(localDirectory.path, '${message.id}_thumbnail.jpg'),
        );
        await generated.copy(thumbnail.path);
        localThumbnailPath = thumbnail.path;
      }

      await _localChatStore.markMediaDownloaded(
        ownerUid: ownerUid,
        chatId: chatId,
        messageId: message.id,
        localMediaPath: destination.path,
        localThumbnailPath: localThumbnailPath,
      );
      await _acknowledgeDownload(
        ownerUid: ownerUid,
        chatId: chatId,
        message: message,
      );
      return destination.path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  Future<void> _acknowledgeDownload({
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
      // The verified local file remains usable. A future open/download attempt
      // retries the idempotent acknowledgement and cloud cleanup.
      developer.log(
        'Private media acknowledgement deferred',
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
