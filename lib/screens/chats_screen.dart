import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_preview_model.dart';
import '../services/announcement_service.dart';
import '../services/in_app_notification_service.dart';
import '../services/trusted_read_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatters.dart';
import 'chat_screen.dart';
import 'nearby_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'support_announcements_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TrustedReadService _trustedReadService = TrustedReadService();
  final AnnouncementService _announcementService = AnnouncementService();
  final InAppNotificationService _notificationService =
      InAppNotificationService();
  final TextEditingController _searchController = TextEditingController();

  List<ChatPreviewModel> _chats = const <ChatPreviewModel>[];
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isNavigating = false;
  String _query = '';
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    unawaited(_loadChats(showLoader: true));
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_loadChats()),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim().toLowerCase();
    if (nextQuery == _query || !mounted) return;
    setState(() => _query = nextQuery);
  }

  Future<void> _loadChats({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final chats = await _trustedReadService.getChatPreviews();
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _loadError = null;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadChats();
  }

  List<ChatPreviewModel> get _visibleChats {
    if (_query.isEmpty) return _chats;
    return _chats
        .where((chat) => chat.otherUserName.toLowerCase().contains(_query))
        .toList();
  }

  int get _privateUnreadCount =>
      _chats.fold<int>(0, (total, chat) => total + chat.unreadCount);

  Future<void> _openChat(ChatPreviewModel chat) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: chat.otherUserId,
          otherUserName: chat.otherUserName,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isNavigating = false);
    await _loadChats();
  }

  Color _avatarColor(String seed) {
    const colors = <Color>[
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFFF97316),
      Color(0xFF22C55E),
      Color(0xFF6366F1),
    ];
    final hash = seed.codeUnits.fold<int>(0, (value, unit) => value + unit);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'User not logged in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(currentUser.uid),
      ),
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
    );
  }

  Widget _buildBody(String currentUserId) {
    if (_isLoading && _chats.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_loadError != null && _chats.isEmpty) {
      return _ErrorState(onRetry: () => _loadChats(showLoader: true));
    }

    final visibleChats = _visibleChats;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: <Widget>[
                _Header(
                  searchController: _searchController,
                  notificationService: _notificationService,
                  currentUserId: currentUserId,
                  isRefreshing: _isRefreshing,
                  onRefresh: _refresh,
                  onNotifications: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.chat_bubble_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recent Chats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${visibleChats.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          if (visibleChats.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                isSearching: _query.isNotEmpty,
                onFindPeople: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyScreen()),
                ),
                onClearSearch: _searchController.clear,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.separated(
                itemCount: visibleChats.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return StreamBuilder<int>(
                      stream: _announcementService.watchUnreadCount(
                        currentUserId,
                      ),
                      builder: (context, snapshot) => _SupportCard(
                        unreadCount: snapshot.data ?? 0,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SupportAnnouncementsScreen(),
                          ),
                        ),
                      ),
                    );
                  }

                  final chat = visibleChats[index - 1];
                  return _ChatCard(
                    chat: chat,
                    currentUserId: currentUserId,
                    avatarColor: _avatarColor(chat.otherUserId),
                    onTap: () => _openChat(chat),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searchController,
    required this.notificationService,
    required this.currentUserId,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onNotifications,
  });

  final TextEditingController searchController;
  final InAppNotificationService notificationService;
  final String currentUserId;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF24133B), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.mark_unread_chat_alt_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Chats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Your private NearMeU conversations',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh chats',
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
              StreamBuilder<int>(
                stream: notificationService.watchUnreadCount(currentUserId),
                builder: (context, snapshot) => _BadgeIcon(
                  count: snapshot.data ?? 0,
                  child: IconButton(
                    tooltip: 'Notifications',
                    onPressed: onNotifications,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search conversations',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: .28),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.chat,
    required this.currentUserId,
    required this.avatarColor,
    required this.onTap,
  });

  final ChatPreviewModel chat;
  final String currentUserId;
  final Color avatarColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sentByCurrentUser = chat.lastMessageSenderId == currentUserId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: chat.unreadCount > 0
                  ? AppColors.primary.withValues(alpha: .65)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: avatarColor,
                    child: Text(
                      chat.otherUserName.isEmpty
                          ? '?'
                          : chat.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: 1,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: chat.isOtherUserOnline == true
                            ? AppColors.online
                            : AppColors.offline,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      chat.otherUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        if (sentByCurrentUser) ...<Widget>[
                          Icon(
                            chat.lastMessageSeen == true
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            color: chat.lastMessageSeen == true
                                ? const Color(0xFF38BDF8)
                                : AppColors.textHint,
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            chat.previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: chat.unreadCount > 0
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    DateFormatters.chatPreview(chat.lastMessageTime),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (chat.unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                      child: Text(
                        chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF2A173F),
        child: Icon(Icons.campaign_rounded, color: AppColors.primaryLight),
      ),
      title: const Text(
        'NearMeU Support',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      subtitle: const Text(
        'Announcements and safety updates',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: unreadCount > 0
          ? _BadgeIcon(
              count: unreadCount,
              child: const Icon(Icons.chevron_right, color: Colors.white70),
            )
          : const Icon(Icons.chevron_right, color: Colors.white70),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearching,
    required this.onFindPeople,
    required this.onClearSearch,
  });

  final bool isSearching;
  final VoidCallback onFindPeople;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.forum_outlined,
              color: AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: 18),
            Text(
              isSearching ? 'No matching chats' : 'No conversations yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try another name or clear your search.'
                  : 'Start chatting with someone from Nearby.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isSearching ? onClearSearch : onFindPeople,
              icon: Icon(
                isSearching ? Icons.close_rounded : Icons.location_on_rounded,
              ),
              label: Text(isSearching ? 'Clear Search' : 'Find People'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: 18),
            const Text(
              'Could not load chats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        if (count > 0)
          Positioned(
            right: -7,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
