import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/local_stored_message.dart';
import '../models/message_model.dart';

class LocalChatStore {
  LocalChatStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const int _databaseVersion = 2;
  static const String _keyPrefix = 'nearmeu_local_chat_key_v1_';
  static const Duration cloudMessageRetention = Duration(days: 7);

  final FlutterSecureStorage _secureStorage;
  static final Map<String, Database> _openDatabases = <String, Database>{};
  static final Map<String, Future<Database>> _openingDatabases =
      <String, Future<Database>>{};

  String _safeUid(String uid) {
    return uid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  String _keyName(String uid) => '$_keyPrefix${_safeUid(uid)}';

  Future<String> _databasePath(String uid) async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'chat_${_safeUid(uid)}.db');
  }

  Future<Directory> _privateMediaRoot(String uid) async {
    final directory = await getApplicationSupportDirectory();
    return Directory(p.join(directory.path, 'private_media', _safeUid(uid)));
  }

  Future<String> _databasePassword(String uid) async {
    final keyName = _keyName(uid);
    final existing = await _secureStorage.read(key: keyName);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final generated = base64UrlEncode(bytes);
    await _secureStorage.write(key: keyName, value: generated);
    return generated;
  }

  Future<Database> openForUser(String uid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'A signed-in user is required.');
    }

    final cached = _openDatabases[uid];
    if (cached != null && cached.isOpen) return cached;

    final opening = _openingDatabases[uid];
    if (opening != null) return opening;

    final future = _openForUserInternal(uid);
    _openingDatabases[uid] = future;
    try {
      return await future;
    } finally {
      if (identical(_openingDatabases[uid], future)) {
        _openingDatabases.remove(uid);
      }
    }
  }

  Future<Database> _openForUserInternal(String uid) async {
    final path = await _databasePath(uid);
    final parent = Directory(p.dirname(path));
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final password = await _databasePassword(uid);
    final database = await openDatabase(
      path,
      password: password,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            owner_uid TEXT NOT NULL,
            chat_id TEXT NOT NULL,
            message_id TEXT NOT NULL,
            sender_id TEXT NOT NULL,
            receiver_id TEXT NOT NULL,
            text TEXT NOT NULL DEFAULT '',
            timestamp_ms INTEGER NOT NULL,
            is_unsent INTEGER NOT NULL DEFAULT 0,
            unsent_at_ms INTEGER,
            reply_to_message_id TEXT,
            reply_to_text TEXT,
            reply_to_sender_id TEXT,
            message_type TEXT NOT NULL DEFAULT 'text',
            remote_media_url TEXT,
            media_storage_path TEXT,
            media_content_type TEXT,
            media_size_bytes INTEGER,
            media_duration_ms INTEGER,
            download_ack_json TEXT NOT NULL DEFAULT '{}',
            local_media_path TEXT,
            local_thumbnail_path TEXT,
            is_seen INTEGER NOT NULL DEFAULT 0,
            seen_at_ms INTEGER,
            deleted_for_json TEXT NOT NULL DEFAULT '[]',
            cloud_expires_at_ms INTEGER,
            cloud_media_deleted_at_ms INTEGER,
            download_complete INTEGER NOT NULL DEFAULT 0,
            cloud_media_deleted INTEGER NOT NULL DEFAULT 0,
            pending_upload INTEGER NOT NULL DEFAULT 0,
            updated_at_ms INTEGER NOT NULL,
            PRIMARY KEY (owner_uid, chat_id, message_id)
          )
        ''');
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE messages ADD COLUMN media_storage_path TEXT',
          );
          await db.execute(
            'ALTER TABLE messages ADD COLUMN media_content_type TEXT',
          );
          await db.execute(
            'ALTER TABLE messages ADD COLUMN media_size_bytes INTEGER',
          );
          await db.execute(
            'ALTER TABLE messages ADD COLUMN media_duration_ms INTEGER',
          );
          await db.execute(
            "ALTER TABLE messages ADD COLUMN download_ack_json TEXT NOT NULL DEFAULT '{}'",
          );
          await db.execute(
            'ALTER TABLE messages ADD COLUMN cloud_media_deleted_at_ms INTEGER',
          );
        }
        await _createIndexes(db);
      },
    );
    _openDatabases[uid] = database;
    return database;
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS messages_chat_time_idx '
      'ON messages(owner_uid, chat_id, timestamp_ms)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS messages_cloud_expiry_idx '
      'ON messages(owner_uid, cloud_expires_at_ms)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS messages_pending_upload_idx '
      'ON messages(owner_uid, pending_upload, updated_at_ms)',
    );
  }

  Future<void> saveRemoteMessages({
    required String ownerUid,
    required String chatId,
    required Iterable<MessageModel> messages,
  }) async {
    final existingRecords = await loadMessages(
      ownerUid: ownerUid,
      chatId: chatId,
      limit: 2000,
    );
    final existingById = <String, LocalStoredMessage>{
      for (final record in existingRecords) record.message.id: record,
    };

    final records = messages.map((message) {
      final existing = existingById[message.id];
      final localMediaPath = existing?.localMediaPath;
      final localThumbnailPath = existing?.localThumbnailPath;
      return LocalStoredMessage(
        chatId: chatId,
        message: message.withLocalMedia(
          localMediaPath: localMediaPath,
          localThumbnailPath: localThumbnailPath,
        ),
        localMediaPath: localMediaPath,
        localThumbnailPath: localThumbnailPath,
        cloudExpiresAt:
            message.cloudExpiresAt ??
            existing?.cloudExpiresAt ??
            message.timestamp.add(cloudMessageRetention),
        downloadComplete:
            message.type == 'text' || (existing?.downloadComplete ?? false),
        cloudMediaDeleted:
            message.cloudMediaDeletedAt != null ||
            (existing?.cloudMediaDeleted ?? false),
        pendingUpload: false,
      );
    });
    await upsertMessages(ownerUid: ownerUid, records: records);
  }

  Future<void> upsertMessages({
    required String ownerUid,
    required Iterable<LocalStoredMessage> records,
  }) async {
    final database = await openForUser(ownerUid);
    final batch = database.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final record in records) {
      final message = record.message;
      final acknowledgements = message.downloadAcknowledgements.map(
        (uid, acknowledgedAt) =>
            MapEntry(uid, acknowledgedAt.millisecondsSinceEpoch),
      );
      batch.insert('messages', <String, Object?>{
        'owner_uid': ownerUid,
        'chat_id': record.chatId,
        'message_id': message.id,
        'sender_id': message.senderId,
        'receiver_id': message.receiverId,
        'text': message.text,
        'timestamp_ms': message.timestamp.millisecondsSinceEpoch,
        'is_unsent': message.isUnsent ? 1 : 0,
        'unsent_at_ms': message.unsentAt?.millisecondsSinceEpoch,
        'reply_to_message_id': message.replyToMessageId,
        'reply_to_text': message.replyToText,
        'reply_to_sender_id': message.replyToSenderId,
        'message_type': message.type,
        'remote_media_url': message.mediaUrl,
        'media_storage_path': message.mediaStoragePath,
        'media_content_type': message.mediaContentType,
        'media_size_bytes': message.mediaSizeBytes,
        'media_duration_ms': message.mediaDurationMs,
        'download_ack_json': jsonEncode(acknowledgements),
        'local_media_path': record.localMediaPath ?? message.localMediaPath,
        'local_thumbnail_path':
            record.localThumbnailPath ?? message.localThumbnailPath,
        'is_seen': message.isSeen ? 1 : 0,
        'seen_at_ms': message.seenAt?.millisecondsSinceEpoch,
        'deleted_for_json': jsonEncode(message.deletedFor),
        'cloud_expires_at_ms': (record.cloudExpiresAt ?? message.cloudExpiresAt)
            ?.millisecondsSinceEpoch,
        'cloud_media_deleted_at_ms':
            message.cloudMediaDeletedAt?.millisecondsSinceEpoch,
        'download_complete': record.downloadComplete ? 1 : 0,
        'cloud_media_deleted': record.cloudMediaDeleted ? 1 : 0,
        'pending_upload': record.pendingUpload ? 1 : 0,
        'updated_at_ms': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<LocalStoredMessage>> loadMessages({
    required String ownerUid,
    required String chatId,
    int limit = 500,
  }) async {
    final database = await openForUser(ownerUid);
    final rows = await database.query(
      'messages',
      where: 'owner_uid = ? AND chat_id = ?',
      whereArgs: <Object?>[ownerUid, chatId],
      orderBy: 'timestamp_ms ASC',
      limit: limit.clamp(1, 2000),
    );
    return rows.map(_recordFromRow).toList(growable: false);
  }

  Future<List<LocalStoredMessage>> loadPendingUploads({
    required String ownerUid,
    String? chatId,
    int limit = 50,
  }) async {
    final database = await openForUser(ownerUid);
    final hasChat = chatId != null && chatId.trim().isNotEmpty;
    final rows = await database.query(
      'messages',
      where: hasChat
          ? 'owner_uid = ? AND chat_id = ? AND pending_upload = 1'
          : 'owner_uid = ? AND pending_upload = 1',
      whereArgs: hasChat ? <Object?>[ownerUid, chatId] : <Object?>[ownerUid],
      orderBy: 'updated_at_ms ASC',
      limit: limit.clamp(1, 200),
    );
    return rows.map(_recordFromRow).toList(growable: false);
  }

  Future<List<MessageModel>> loadVisibleMessages({
    required String ownerUid,
    required String chatId,
    int limit = 2000,
  }) async {
    final records = await loadMessages(
      ownerUid: ownerUid,
      chatId: chatId,
      limit: limit,
    );
    return records
        .where((record) => !record.message.deletedFor.contains(ownerUid))
        .map((record) => record.message)
        .toList(growable: false);
  }

  LocalStoredMessage _recordFromRow(Map<String, Object?> row) {
    List<String> deletedFor = const <String>[];
    final deletedForJson = row['deleted_for_json'];
    if (deletedForJson is String && deletedForJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(deletedForJson);
        if (decoded is List) deletedFor = decoded.whereType<String>().toList();
      } on FormatException {
        deletedFor = const <String>[];
      }
    }

    final acknowledgements = <String, DateTime>{};
    final acknowledgementJson = row['download_ack_json'];
    if (acknowledgementJson is String && acknowledgementJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(acknowledgementJson);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final milliseconds = entry.value;
            if (entry.key is String && milliseconds is num) {
              acknowledgements[entry.key as String] =
                  DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt());
            }
          }
        }
      } on FormatException {
        acknowledgements.clear();
      }
    }

    DateTime? dateFromMillis(Object? value) {
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      return null;
    }

    final localMediaPath = row['local_media_path'] as String?;
    final localThumbnailPath = row['local_thumbnail_path'] as String?;
    final cloudExpiresAt = dateFromMillis(row['cloud_expires_at_ms']);
    final cloudMediaDeletedAt = dateFromMillis(
      row['cloud_media_deleted_at_ms'],
    );
    final message = MessageModel(
      id: row['message_id']! as String,
      senderId: row['sender_id']! as String,
      receiverId: row['receiver_id']! as String,
      text: (row['text'] as String?) ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        row['timestamp_ms']! as int,
      ),
      isUnsent: row['is_unsent'] == 1,
      unsentAt: dateFromMillis(row['unsent_at_ms']),
      replyToMessageId: row['reply_to_message_id'] as String?,
      replyToText: row['reply_to_text'] as String?,
      replyToSenderId: row['reply_to_sender_id'] as String?,
      type: (row['message_type'] as String?) ?? 'text',
      mediaUrl: row['remote_media_url'] as String?,
      mediaStoragePath: row['media_storage_path'] as String?,
      mediaContentType: row['media_content_type'] as String?,
      mediaSizeBytes: row['media_size_bytes'] as int?,
      mediaDurationMs: row['media_duration_ms'] as int?,
      downloadAcknowledgements: acknowledgements,
      cloudExpiresAt: cloudExpiresAt,
      cloudMediaDeletedAt: cloudMediaDeletedAt,
      localMediaPath: localMediaPath,
      localThumbnailPath: localThumbnailPath,
      isSeen: row['is_seen'] == 1,
      seenAt: dateFromMillis(row['seen_at_ms']),
      deletedFor: deletedFor,
    );

    return LocalStoredMessage(
      chatId: row['chat_id']! as String,
      message: message,
      localMediaPath: localMediaPath,
      localThumbnailPath: localThumbnailPath,
      cloudExpiresAt: cloudExpiresAt,
      downloadComplete: row['download_complete'] == 1,
      cloudMediaDeleted:
          row['cloud_media_deleted'] == 1 || cloudMediaDeletedAt != null,
      pendingUpload: row['pending_upload'] == 1,
    );
  }

  Future<void> markMediaDownloaded({
    required String ownerUid,
    required String chatId,
    required String messageId,
    required String localMediaPath,
    String? localThumbnailPath,
  }) async {
    final database = await openForUser(ownerUid);
    await database.update(
      'messages',
      <String, Object?>{
        'local_media_path': localMediaPath,
        'local_thumbnail_path': localThumbnailPath,
        'download_complete': 1,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'owner_uid = ? AND chat_id = ? AND message_id = ?',
      whereArgs: <Object?>[ownerUid, chatId, messageId],
    );
  }

  Future<void> markCloudMediaDeleted({
    required String ownerUid,
    required String chatId,
    required String messageId,
    DateTime? deletedAt,
  }) async {
    final database = await openForUser(ownerUid);
    final timestamp = deletedAt ?? DateTime.now();
    await database.update(
      'messages',
      <String, Object?>{
        'remote_media_url': null,
        'cloud_media_deleted_at_ms': timestamp.millisecondsSinceEpoch,
        'cloud_media_deleted': 1,
        'updated_at_ms': timestamp.millisecondsSinceEpoch,
      },
      where: 'owner_uid = ? AND chat_id = ? AND message_id = ?',
      whereArgs: <Object?>[ownerUid, chatId, messageId],
    );
  }

  Future<void> markMessageUnsent({
    required String ownerUid,
    required String chatId,
    required String messageId,
    required DateTime unsentAt,
  }) async {
    final database = await openForUser(ownerUid);
    await database.update(
      'messages',
      <String, Object?>{
        'text': '',
        'is_unsent': 1,
        'unsent_at_ms': unsentAt.millisecondsSinceEpoch,
        'reply_to_message_id': null,
        'reply_to_text': null,
        'reply_to_sender_id': null,
        'remote_media_url': null,
        'media_storage_path': null,
        'cloud_media_deleted': 1,
        'cloud_media_deleted_at_ms': unsentAt.millisecondsSinceEpoch,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'owner_uid = ? AND chat_id = ? AND message_id = ?',
      whereArgs: <Object?>[ownerUid, chatId, messageId],
    );
  }

  Future<int> clearExpiredRemoteReferences({
    required String ownerUid,
    DateTime? now,
  }) async {
    final database = await openForUser(ownerUid);
    final cutoff = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return database.update(
      'messages',
      <String, Object?>{
        'remote_media_url': null,
        'cloud_media_deleted_at_ms': cutoff,
        'cloud_media_deleted': 1,
        'updated_at_ms': cutoff,
      },
      where:
          'owner_uid = ? AND cloud_expires_at_ms IS NOT NULL '
          'AND cloud_expires_at_ms <= ? AND download_complete = 1',
      whereArgs: <Object?>[ownerUid, cutoff],
    );
  }

  Future<void> deleteMessageForOwner({
    required String ownerUid,
    required String chatId,
    required String messageId,
  }) async {
    final database = await openForUser(ownerUid);
    final rows = await database.query(
      'messages',
      columns: const <String>['local_media_path', 'local_thumbnail_path'],
      where: 'owner_uid = ? AND chat_id = ? AND message_id = ?',
      whereArgs: <Object?>[ownerUid, chatId, messageId],
      limit: 1,
    );
    await database.delete(
      'messages',
      where: 'owner_uid = ? AND chat_id = ? AND message_id = ?',
      whereArgs: <Object?>[ownerUid, chatId, messageId],
    );
    if (rows.isNotEmpty) {
      await _deleteFile(rows.first['local_media_path'] as String?);
      await _deleteFile(rows.first['local_thumbnail_path'] as String?);
    }
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Database privacy state is authoritative. Files that are temporarily
      // locked can be removed by account cleanup later.
    }
  }

  Future<void> closeForUser(String uid) async {
    await _openingDatabases.remove(uid);
    final database = _openDatabases.remove(uid);
    if (database != null && database.isOpen) await database.close();
  }

  Future<void> clearAccount(String uid) async {
    await closeForUser(uid);
    final databasePath = await _databasePath(uid);
    await deleteDatabase(databasePath);
    await _secureStorage.delete(key: _keyName(uid));

    final mediaRoot = await _privateMediaRoot(uid);
    try {
      if (await mediaRoot.exists()) {
        await mediaRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // Auth/database removal still succeeds. The app-private directory is
      // inaccessible to other accounts and can be retried on the next cleanup.
    }
  }
}
