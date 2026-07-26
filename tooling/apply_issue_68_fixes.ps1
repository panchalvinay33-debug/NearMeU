$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Replace-RegexOnce {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Pattern,
        [Parameter(Mandatory)] [string] $Replacement
    )

    $content = Get-Content -Raw -LiteralPath $Path
    $regex = [regex]::new(
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $matches = $regex.Matches($content)
    if ($matches.Count -ne 1) {
        throw "Expected exactly one source match in $Path, found $($matches.Count)."
    }
    $updated = $regex.Replace($content, $Replacement, 1)
    [System.IO.File]::WriteAllText(
        $Path,
        $updated,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$root = if ($env:NEARMEU_PROJECT_ROOT) {
    (Resolve-Path $env:NEARMEU_PROJECT_ROOT).Path
} else {
    (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
Set-Location $root

$branch = git branch --show-current
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
    throw "Could not determine the current Git branch in $root."
}
$branch = $branch.Trim()
if ($branch -ne 'fix/release-test-hardening-v1') {
    throw "Run this only on fix/release-test-hardening-v1. Current branch: $branch"
}

Write-Host 'Applying NearMeU issue #68 fixes...' -ForegroundColor Cyan

# 1) Authenticated startup enters the persistent app shell.
$authGate = Join-Path $root 'lib/screens/auth_gate_screen.dart'
Replace-RegexOnce `
    -Path $authGate `
    -Pattern "import 'login_screen\.dart';\s*import 'nearby_screen\.dart';" `
    -Replacement "import 'app_shell_screen.dart';`nimport 'login_screen.dart';"
Replace-RegexOnce `
    -Path $authGate `
    -Pattern "MaterialPageRoute\(builder:\s*\(_\)\s*=>\s*const NearbyScreen\(\)\)," `
    -Replacement "MaterialPageRoute(builder: (_) => const AppShellScreen()),"

# 2) One encrypted SQLCipher database opening per signed-in user, shared across
# all ChatService / PrivateMediaService instances.
$localStore = Join-Path $root 'lib/services/local_chat_store.dart'
$databaseFields = @'
final FlutterSecureStorage _secureStorage;
  static final Map<String, Database> _openDatabases = <String, Database>{};
  static final Map<String, Future<Database>> _openingDatabases =
      <String, Future<Database>>{};
'@
Replace-RegexOnce `
    -Path $localStore `
    -Pattern "final FlutterSecureStorage _secureStorage;\s*final Map<String, Database> _openDatabases = <String, Database>\{\};" `
    -Replacement $databaseFields

$openReplacement = @'
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

  Future<void> _createIndexes
'@
Replace-RegexOnce `
    -Path $localStore `
    -Pattern "Future<Database> openForUser\(String uid\) async \{.*?Future<void> _createIndexes" `
    -Replacement $openReplacement

$closeReplacement = @'
Future<void> closeForUser(String uid) async {
    await _openingDatabases.remove(uid);
    final database = _openDatabases.remove(uid);
'@
Replace-RegexOnce `
    -Path $localStore `
    -Pattern "Future<void> closeForUser\(String uid\) async \{\s*final database = _openDatabases\.remove\(uid\);" `
    -Replacement $closeReplacement

# 3) Chat detail shares one LocalChatStore and repeatedly acknowledges reads
# while the conversation remains visible.
$chatScreen = Join-Path $root 'lib/screens/chat_screen.dart'
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "import 'package:emoji_picker_flutter/emoji_picker_flutter\.dart';" `
    -Replacement "import 'dart:async';`n`nimport 'package:emoji_picker_flutter/emoji_picker_flutter.dart';"
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "import '../services/chat_service\.dart';" `
    -Replacement "import '../services/chat_service.dart';`nimport '../services/local_chat_store.dart';"

$serviceFields = @'
final LocalChatStore _localChatStore = LocalChatStore();
  late final ChatService _chatService = ChatService(
    localChatStore: _localChatStore,
  );
  late final PrivateMediaService _mediaService = PrivateMediaService(
    localChatStore: _localChatStore,
  );
'@
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "final ChatService _chatService = ChatService\(\);\s*final PrivateMediaService _mediaService = PrivateMediaService\(\);" `
    -Replacement $serviceFields

$readFields = @'
bool _checkingBlock = true;
  Timer? _readAcknowledgementTimer;
  bool _isAcknowledgingRead = false;
'@
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "bool _checkingBlock = true;" `
    -Replacement $readFields

$initReplacement = @'
_initChatScreen();
    _readAcknowledgementTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_markChatOpened()),
    );
  }
'@
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "_initChatScreen\(\);\s*\}" `
    -Replacement $initReplacement

$markReadReplacement = @'
Future<void> _markChatOpened() async {
    final user = currentUser;
    if (user == null || _isBlocked || _isAcknowledgingRead) return;
    _isAcknowledgingRead = true;
    try {
      await _userService.updateLastSeen(user.uid);
      await _chatService.markMessagesAsSeen(
        currentUserId: user.uid,
        otherUserId: widget.otherUserId,
      );
    } catch (_) {
      // A later acknowledgement retries transient sync failures.
    } finally {
      _isAcknowledgingRead = false;
    }
  }
'@
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "Future<void> _markChatOpened\(\) async \{.*?\n  \}" `
    -Replacement $markReadReplacement

$disposeReplacement = @'
void dispose() {
    _readAcknowledgementTimer?.cancel();
    final user = currentUser;
'@
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "void dispose\(\) \{\s*final user = currentUser;" `
    -Replacement $disposeReplacement

$messagesReplacement = @'
final messages = snapshot.data ?? <MessageModel>[];
                        if (messages.any(
                          (message) =>
                              message.receiverId == user.uid && !message.isSeen,
                        )) {
                          unawaited(_markChatOpened());
                        }
'@
Replace-RegexOnce `
    -Path $chatScreen `
    -Pattern "final messages = snapshot\.data \?\? <MessageModel>\[\];" `
    -Replacement $messagesReplacement

Write-Host 'Formatting patched Dart files...' -ForegroundColor Cyan
$formatTargets = @(
    'lib/screens/app_shell_screen.dart',
    'lib/screens/auth_gate_screen.dart',
    'lib/screens/chat_screen.dart',
    'lib/services/local_chat_store.dart'
)
& dart format @formatTargets
if ($LASTEXITCODE -ne 0) {
    throw 'dart format failed.'
}

Write-Host 'Running Flutter analysis...' -ForegroundColor Cyan
& flutter analyze
if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze failed.'
}

Write-Host ''
Write-Host 'Issue #68 source patch completed successfully.' -ForegroundColor Green
