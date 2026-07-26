$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Replace-Exact {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Old,
        [Parameter(Mandatory)] [string] $New
    )

    $content = Get-Content -Raw -LiteralPath $Path
    if (-not $content.Contains($Old)) {
        throw "Expected source block was not found in $Path. Stop to avoid an unsafe partial patch."
    }
    Set-Content -LiteralPath $Path -Value ($content.Replace($Old, $New)) -Encoding utf8
}

function Replace-RegexOnce {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Pattern,
        [Parameter(Mandatory)] [string] $Replacement
    )

    $content = Get-Content -Raw -LiteralPath $Path
    $regex = [regex]::new($Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $matches = $regex.Matches($content)
    if ($matches.Count -ne 1) {
        throw "Expected exactly one regex match in $Path, found $($matches.Count)."
    }
    Set-Content -LiteralPath $Path -Value ($regex.Replace($content, $Replacement, 1)) -Encoding utf8
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

$branch = (git branch --show-current).Trim()
if ($branch -ne 'fix/release-test-hardening-v1') {
    throw "Run this only on fix/release-test-hardening-v1. Current branch: $branch"
}

Write-Host 'Applying NearMeU issue #68 fixes...' -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1) Persistent app shell: keep Nearby, Chats and Settings alive.
# ---------------------------------------------------------------------------
$authGate = Join-Path $root 'lib/screens/auth_gate_screen.dart'
Replace-Exact $authGate "import 'login_screen.dart';`nimport 'nearby_screen.dart';" "import 'app_shell_screen.dart';`nimport 'login_screen.dart';"
Replace-Exact $authGate "MaterialPageRoute(builder: (_) => const NearbyScreen())," "MaterialPageRoute(builder: (_) => const AppShellScreen()),"

$nearby = Join-Path $root 'lib/screens/nearby_screen.dart'
Replace-Exact $nearby @'
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});
'@ @'
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key, this.showBottomNavigationBar = true});

  final bool showBottomNavigationBar;
'@
Replace-Exact $nearby @'
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChatsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on_rounded),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: UnreadNavIcon(
              userId: uid,
              icon: Icons.chat_bubble_outline_rounded,
            ),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
'@ @'
      bottomNavigationBar: widget.showBottomNavigationBar
          ? BottomNavigationBar(
              currentIndex: 0,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                if (index == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatsScreen()),
                  );
                } else if (index == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_rounded),
                  label: 'Nearby',
                ),
                BottomNavigationBarItem(
                  icon: UnreadNavIcon(
                    userId: uid,
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  label: 'Chats',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            )
          : null,
'@

$chats = Join-Path $root 'lib/screens/chats_screen.dart'
Replace-Exact $chats @'
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
'@ @'
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, this.showBottomNavigationBar = true});

  final bool showBottomNavigationBar;
'@
Replace-Exact $chats @'
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NearbyScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _announcementService.watchUnreadCount(currentUser.uid),
              builder: (context, announcementSnapshot) => _BadgeIcon(
                count: _privateUnreadCount + (announcementSnapshot.data ?? 0),
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
'@ @'
      bottomNavigationBar: widget.showBottomNavigationBar
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF1A1A1A),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              currentIndex: 1,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyScreen()),
                  );
                } else if (index == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }
              },
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.location_on),
                  label: 'Nearby',
                ),
                BottomNavigationBarItem(
                  icon: StreamBuilder<int>(
                    stream: _announcementService.watchUnreadCount(currentUser.uid),
                    builder: (context, announcementSnapshot) => _BadgeIcon(
                      count: _privateUnreadCount +
                          (announcementSnapshot.data ?? 0),
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                  label: 'Chats',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
'@

# Optimistically clear the row badge immediately, then refresh from backend.
Replace-Exact $chats @'
  Future<void> _openChat(ChatPreviewModel chat) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
'@ @'
  Future<void> _openChat(ChatPreviewModel chat) async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
      _chats = _chats
          .map(
            (item) => item.chatId == chat.chatId
                ? item.copyWith(unreadCount: 0)
                : item,
          )
          .toList(growable: false);
    });
'@

$settings = Join-Path $root 'lib/screens/settings_screen.dart'
Replace-Exact $settings @'
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
'@ @'
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.showBottomNavigationBar = true});

  final bool showBottomNavigationBar;
'@
Replace-Exact $settings @'
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: isDeletingAccount
            ? null
            : (index) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyScreen()),
                  );
                } else if (index == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatsScreen()),
                  );
                }
              },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: UnreadNavIcon(userId: uid, icon: Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
'@ @'
      bottomNavigationBar: widget.showBottomNavigationBar
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF1A1A1A),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              currentIndex: 2,
              onTap: isDeletingAccount
                  ? null
                  : (index) {
                      if (index == 0) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyScreen(),
                          ),
                        );
                      } else if (index == 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatsScreen(),
                          ),
                        );
                      }
                    },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.location_on),
                  label: 'Nearby',
                ),
                BottomNavigationBarItem(
                  icon: UnreadNavIcon(
                    userId: uid,
                    icon: Icons.chat_bubble_outline,
                  ),
                  label: 'Chats',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
'@

# ---------------------------------------------------------------------------
# 2) Encrypted local DB: serialize opening globally across service instances.
# ---------------------------------------------------------------------------
$localStore = Join-Path $root 'lib/services/local_chat_store.dart'
Replace-Exact $localStore @'
  final FlutterSecureStorage _secureStorage;
  final Map<String, Database> _openDatabases = <String, Database>{};
'@ @'
  final FlutterSecureStorage _secureStorage;
  static final Map<String, Database> _openDatabases = <String, Database>{};
  static final Map<String, Future<Database>> _openingDatabases =
      <String, Future<Database>>{};
'@

$openPattern = '  Future<Database> openForUser\(String uid\) async \{.*?\n  \}\n\n  Future<void> _createIndexes'
$openReplacement = @'
  Future<Database> openForUser(String uid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'A signed-in user is required.');
    }

    final cached = _openDatabases[uid];
    if (cached != null && cached.isOpen) return cached;

    final inFlight = _openingDatabases[uid];
    if (inFlight != null) return inFlight;

    final opening = _openForUserInternal(uid);
    _openingDatabases[uid] = opening;
    try {
      return await opening;
    } finally {
      if (identical(_openingDatabases[uid], opening)) {
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
Replace-RegexOnce $localStore $openPattern $openReplacement

Replace-Exact $localStore @'
  Future<void> closeForUser(String uid) async {
    final database = _openDatabases.remove(uid);
'@ @'
  Future<void> closeForUser(String uid) async {
    await _openingDatabases.remove(uid);
    final database = _openDatabases.remove(uid);
'@

# ---------------------------------------------------------------------------
# 3) Chat read lifecycle: repeat acknowledgement while chat is visible and
#    reuse one LocalChatStore for chat + media services.
# ---------------------------------------------------------------------------
$chatScreen = Join-Path $root 'lib/screens/chat_screen.dart'
Replace-Exact $chatScreen "import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';" "import 'dart:async';`n`nimport 'package:emoji_picker_flutter/emoji_picker_flutter.dart';"
Replace-Exact $chatScreen "import '../services/chat_service.dart';" "import '../services/chat_service.dart';`nimport '../services/local_chat_store.dart';"
Replace-Exact $chatScreen @'
class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final PrivateMediaService _mediaService = PrivateMediaService();
'@ @'
class _ChatScreenState extends State<ChatScreen> {
  final LocalChatStore _localChatStore = LocalChatStore();
  late final ChatService _chatService = ChatService(
    localChatStore: _localChatStore,
  );
  late final PrivateMediaService _mediaService = PrivateMediaService(
    localChatStore: _localChatStore,
  );
'@
Replace-Exact $chatScreen @'
  bool _isSendingMedia = false;
  bool _checkingBlock = true;
'@ @'
  bool _isSendingMedia = false;
  bool _checkingBlock = true;
  Timer? _readAcknowledgementTimer;
  bool _isAcknowledgingRead = false;
'@
Replace-Exact $chatScreen @'
    _initChatScreen();
  }
'@ @'
    _initChatScreen();
    _readAcknowledgementTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_markChatOpened()),
    );
  }
'@
Replace-Exact $chatScreen @'
  Future<void> _markChatOpened() async {
    final user = currentUser;
    if (user == null || _isBlocked) return;
    await _userService.updateLastSeen(user.uid);
    await _chatService.markMessagesAsSeen(
      currentUserId: user.uid,
      otherUserId: widget.otherUserId,
    );
  }
'@ @'
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
      // The next periodic acknowledgement retries transient sync failures.
    } finally {
      _isAcknowledgingRead = false;
    }
  }
'@
Replace-Exact $chatScreen @'
    final user = currentUser;
    if (user != null) _userService.updateLastSeen(user.uid);
'@ @'
    _readAcknowledgementTimer?.cancel();
    final user = currentUser;
    if (user != null) _userService.updateLastSeen(user.uid);
'@
Replace-Exact $chatScreen @'
                        final messages = snapshot.data ?? <MessageModel>[];
                        WidgetsBinding.instance.addPostFrameCallback(
'@ @'
                        final messages = snapshot.data ?? <MessageModel>[];
                        if (messages.any(
                          (message) =>
                              message.receiverId == user.uid && !message.isSeen,
                        )) {
                          unawaited(_markChatOpened());
                        }
                        WidgetsBinding.instance.addPostFrameCallback(
'@

Write-Host 'Formatting patched Dart files...' -ForegroundColor Cyan
dart format lib/screens/app_shell_screen.dart lib/screens/auth_gate_screen.dart lib/screens/nearby_screen.dart lib/screens/chats_screen.dart lib/screens/settings_screen.dart lib/screens/chat_screen.dart lib/services/local_chat_store.dart

Write-Host 'Running Flutter analysis...' -ForegroundColor Cyan
flutter analyze

Write-Host ''
Write-Host 'Issue #68 source patch completed successfully.' -ForegroundColor Green
Write-Host 'Review git diff, then run Flutter tests and a two-account device test.' -ForegroundColor Green
