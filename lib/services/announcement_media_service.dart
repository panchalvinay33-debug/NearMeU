import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/support_announcement.dart';
import 'private_media_service.dart';

class AnnouncementMediaUpload {
  const AnnouncementMediaUpload({
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

  String get extension => switch (type) {
        'video' => 'mp4',
        'voice' => 'm4a',
        _ => 'jpg',
      };
}

class UploadedAnnouncementMedia {
  const UploadedAnnouncementMedia({
    required this.storagePath,
    required this.type,
    required this.contentType,
    required this.sizeBytes,
    this.durationMs,
  });

  final String storagePath;
  final String type;
  final String contentType;
  final int sizeBytes;
  final int? durationMs;
}

class AnnouncementMediaService {
  AnnouncementMediaService({
    FirebaseStorage? storage,
    PrivateMediaService? privateMediaService,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _privateMediaService = privateMediaService ?? PrivateMediaService();

  static const Duration cloudRetention = Duration(days: 7);
  static const int maximumVoiceBytes = 8 * 1024 * 1024;
  static const Duration maximumVoiceDuration = Duration(minutes: 2);

  final FirebaseStorage _storage;
  final PrivateMediaService _privateMediaService;

  Future<AnnouncementMediaUpload?> pickImage() async {
    final media = await _privateMediaService.pickImage();
    if (media == null) return null;
    return AnnouncementMediaUpload(
      file: media.file,
      type: 'image',
      contentType: media.contentType,
      sizeBytes: media.sizeBytes,
    );
  }

  Future<AnnouncementMediaUpload?> pickVideo() async {
    final media = await _privateMediaService.pickVideo();
    if (media == null) return null;
    return AnnouncementMediaUpload(
      file: media.file,
      type: 'video',
      contentType: media.contentType,
      sizeBytes: media.sizeBytes,
      durationMs: media.durationMs,
    );
  }

  Future<AnnouncementMediaUpload> prepareVoice({
    required File file,
    required int durationMs,
  }) async {
    if (!await file.exists()) {
      throw const PrivateMediaException('The recorded voice file is missing.');
    }
    if (durationMs < 700) {
      throw const PrivateMediaException('Voice recording is too short.');
    }
    if (durationMs > maximumVoiceDuration.inMilliseconds) {
      throw const PrivateMediaException(
        'Voice recording must be two minutes or shorter.',
      );
    }
    final bytes = await file.length();
    if (bytes <= 0 || bytes > maximumVoiceBytes) {
      throw const PrivateMediaException(
        'Voice recording must be smaller than 8 MB.',
      );
    }
    return AnnouncementMediaUpload(
      file: file,
      type: 'voice',
      contentType: 'audio/mp4',
      sizeBytes: bytes,
      durationMs: durationMs,
    );
  }

  Future<UploadedAnnouncementMedia> upload({
    required String adminId,
    required String announcementId,
    required AnnouncementMediaUpload media,
  }) async {
    final storagePath =
        'announcementMedia/$announcementId/media.${media.extension}';
    final reference = _storage.ref().child(storagePath);
    await reference.putFile(
      media.file,
      SettableMetadata(
        contentType: media.contentType,
        cacheControl: 'private,max-age=0,no-store',
        customMetadata: <String, String>{
          'adminId': adminId,
          'announcementId': announcementId,
          'mediaType': media.type,
        },
      ),
    );
    return UploadedAnnouncementMedia(
      storagePath: storagePath,
      type: media.type,
      contentType: media.contentType,
      sizeBytes: media.sizeBytes,
      durationMs: media.durationMs,
    );
  }

  Future<String> ensureLocalCopy({
    required String ownerUid,
    required SupportAnnouncement announcement,
  }) async {
    final storagePath = announcement.mediaStoragePath;
    if (!announcement.hasMedia ||
        announcement.isMediaExpired ||
        storagePath == null ||
        storagePath.isEmpty) {
      throw const PrivateMediaException(
        'This announcement media is no longer available.',
      );
    }

    final directory = await _localDirectory(
      ownerUid: ownerUid,
      announcementId: announcement.id,
    );
    final extension = switch (announcement.mediaType) {
      'video' => 'mp4',
      'voice' => 'm4a',
      _ => 'jpg',
    };
    final destination = File(p.join(directory.path, 'media.$extension'));
    if (await destination.exists()) return destination.path;

    final partial = File('${destination.path}.part');
    if (await partial.exists()) await partial.delete();
    try {
      await _storage.ref().child(storagePath).writeToFile(partial);
      final bytes = await partial.length();
      if (bytes <= 0 ||
          (announcement.mediaSizeBytes != null &&
              bytes != announcement.mediaSizeBytes)) {
        await partial.delete();
        throw const PrivateMediaException(
          'The downloaded announcement media did not pass verification.',
        );
      }
      await partial.rename(destination.path);
      return destination.path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  Future<void> deleteUploadedMedia(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    try {
      await _storage.ref().child(storagePath).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  Future<Directory> _localDirectory({
    required String ownerUid,
    required String announcementId,
  }) async {
    final support = await getApplicationSupportDirectory();
    final safeOwner = ownerUid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final safeAnnouncement =
        announcementId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final directory = Directory(
      p.join(
        support.path,
        'announcement_media',
        safeOwner,
        safeAnnouncement,
      ),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
