import 'dart:convert';
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

  static const int _databaseVersion = 1;
  static const String _keyPrefix = 'nearmeu_local_chat_key_v1_';
  static const Duration cloudMessageRetention = Duration(days: 7);

  final FlutterSecureStorage _secureStorage;
  final Map<String, Database> _openDatabases = <String, Database>{};

  String _safeUid(String uid) {
    return uid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  String _keyName(String uid) => '$_keyPrefix${_safeUid(uid)}';

  Future<String> _databasePath(String uid) async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'chat_${_safeUid(uid)}.db');
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

    final path = await _databasePath(uid);
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
            local_media_path TEXT,
            local_thumbnail_path TEXT,
            is_seen INTEGER NOT NULL DEFAULT 0,
            seen_at_ms INTEGER,
            deleted_for_json TEXT NOT NULL DEFAULT '[]',
            cloud_expires_at_ms INTEGER,
            download_complete INTEGER NOT NULL DEFAULT 0,
            cloud_media_deleted INTEGER NOT NULL DEFAULT 0,
            pending_upload INTEGER NOT NULL DEFAULT 0,
            updated_at_ms INTEGER NOT NULL,
            PRIMARY KEY (owner_uid, chat_id, message_id)
          )
        ''');
        await db.execute(
          'CREATE INDEX messages_chat_time_idx '
          'ON messages(owner_uid, chat_id, timestamp_ms)',
        );
        await db.execute(
          'CREATE INDEX messages_cloud_expiry_idx '
          'ON messages(owner_uid, cloud_expires_at_ms)',
        );
      },
    );
    _openDatabases[uid] = database;
    return database;
  }

  Future<void> saveRemoteMessages({
    required String ownerUid,
    required String chatId,
    required Iterable<MessageModel> messages,
  }) async {
    // Remote snapshots do not carry device-only fields. Merge them with the
    // existing encrypted records so a refresh never erases a downloaded file,
    // thumbnail or download acknowledgement.
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
      return LocalStoredMessage(
        chatId: chatId,
        message: message,
        localMediaPath: existing?.localMediaPath,
        localThumbnailPath: existing?.localThumbnailPath,
        cloudExpiresAt:
            existing?.cloudExpiresAt ??
            message.timestamp.add(cloudMessageRetention),
        downloadComplete:
            message.type == 'text' || (existing?.downloadComplete ?? false),
        cloudMediaDeleted: existing?.cloudMediaDeleted ?? false,
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
      batch.insert(
        'messages',
        <String, Object?>{
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
          'local_media_path': record.localMediaPath,
          'local_thumbnail_path': record.localThumbnailPath,
          'is_seen': message.isSeen ? 1 : 0,
          'seen_at_ms': message.seenAt?.millisecondsSinceEpoch,
          'deleted_for_json': jsonEncode(message.deletedFor),
          'cloud_expires_at_ms': record.cloudExpiresAt?.millisecondsSinceEpoch,
          'download_complete': record.downloadComplete ? 1 : 0,
          'cloud_media_deleted': record.cloudMediaDeleted ? 1 : 0,
          'pending_upload': record.pendingUpload ? 1 : 0,
          'updated_at_ms': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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

    DateTime? dateFromMillis(Object? value) {
      return value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
    }

    final message = MessageModel(
      id: row['message_id']! as String,
      senderId: row['sender_id']! as String,
      receiverId: row['receiver_id']! as String,
      text: (row['text'] as String?) ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp_ms']! as int),
      isUnsent: row['is_unsent'] == 1,
      unsentAt: dateFromMillis(row['unsent_at_ms']),
      replyToMessageId: row['reply_to_message_id'] as String?,
      replyToText: row['reply_to_text'] as String?,
      replyToSenderId: row['reply_to_sender_id'] as String?,
      type: (row['message_type'] as String?) ?? 'text',
      mediaUrl: row['remote_media_url'] as String?,
      isSeen: row['is_seen'] == 1,
      seenAt: dateFromMillis(row['seen_at_ms']),
      deletedFor: deletedFor,
    );

    return LocalStoredMessage(
      chatId: row['chat_id']! as String,
      message: message,
      localMediaPath: row['local_media_path'] as String?,
      localThumbnailPath: row['local_thumbnail_path'] as String?,
      cloudExpiresAt: dateFromMillis(row['cloud_expires_at_ms']),
      downloadComplete: row['download_complete'] == 1,
      cloudMediaDeleted: row['cloud_media_deleted'] == 1,
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
  }) async {
    final database = await openForUser(ownerUid);
    await database.update(
      'messages',
      <String, Object?>{
        'remote_media_url': null,
        'cloud_media_deleted': 1,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
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
    await database.delete(
      'messages',
      where: 'owner_uid = ? AND chat_id = ? AND message_id = ?',
      whereArgs: <Object?>[ownerUid, chatId, messageId],
    );
  }

  Future<void> closeForUser(String uid) async {
    final database = _openDatabases.remove(uid);
    if (database != null && database.isOpen) await database.close();
  }

  Future<void> clearAccount(String uid) async {
    await closeForUser(uid);
    final path = await _databasePath(uid);
    await deleteDatabase(path);
    await _secureStorage.delete(key: _keyName(uid));
  }
}
