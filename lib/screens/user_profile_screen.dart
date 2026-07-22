import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;
  final bool loadBlockState;

  const UserProfileScreen({
    super.key,
    required this.user,
    this.loadBlockState = true,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();

  bool _isLoadingBlockState = true;
  bool _isBlockedEitherWay = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;
  AppUser get user => widget.user;

  @override
  void initState() {
    super.initState();
    if (widget.loadBlockState) {
      _loadBlockState();
    } else {
      _isLoadingBlockState = false;
    }
  }

  Future<void> _loadBlockState() async {
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingBlockState = false;
      });
      return;
    }

    try {
      final blockedByMe = await _userService.isUserBlockedByMe(
        currentUserId: currentUser!.uid,
        targetUserId: user.uid,
      );

      final blockedEitherWay = await _userService.isBlockedEitherWay(
        currentUserId: currentUser!.uid,
        otherUserId: user.uid,
      );

      if (!mounted) return;
      setState(() {
        _isBlockedEitherWay = blockedEitherWay || blockedByMe;
        _isLoadingBlockState = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingBlockState = false;
      });
    }
  }

  String _locationText() {
    final parts = <String>[];

    if (user.city != null && user.city!.trim().isNotEmpty) {
      parts.add(user.city!.trim());
    }

    if (user.state != null &&
        user.state!.trim().isNotEmpty &&
        user.state!.trim() != user.city?.trim()) {
      parts.add(user.state!.trim());
    }

    if (parts.isEmpty) {
      return 'Location unavailable';
    }

    return parts.join(', ');
  }

  Widget _buildAvatar() {
    final firstLetter =
        user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 70,
      backgroundColor: Colors.purpleAccent,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 58,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.purpleAccent,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(String displayName) async {
    if (currentUser == null) return;

    if (_isBlockedEitherWay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot chat with this user right now.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: user.uid,
          otherUserName: displayName,
        ),
      ),
    );
  }

  String _lastSeenText() {
    if (user.isOnline) return 'Online now';
    final lastSeen = user.lastSeen;
    if (lastSeen == null) return 'Last seen recently';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours} hr ago';
    return 'Last seen ${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  String _distanceText() {
    if (user.latitude == null || user.longitude == null) {
      return 'Distance unavailable';
    }
    return 'Distance available in Nearby';
  }

  Widget _hero(String displayName, String displayAge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: .18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 18),
          Text(
            '$displayName$displayAge',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(user.isOnline ? Icons.circle : Icons.schedule_rounded, _lastSeenText(), user.isOnline ? Colors.greenAccent : Colors.white70),
              _pill(Icons.location_city_rounded, _locationText(), Colors.white70),
              _pill(Icons.near_me_rounded, _distanceText(), Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, color: color, size: 15), const SizedBox(width: 7), Flexible(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),],
      ),
    );
  }

  Widget _buildActionButtons(String displayName) {
    if (_isLoadingBlockState) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: CircularProgressIndicator(color: Colors.purpleAccent),
      );
    }

    final chatEnabled = !_isBlockedEitherWay;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: chatEnabled ? () => _openChat(displayName) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: chatEnabled ? Colors.purpleAccent : Colors.grey.shade800,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              disabledBackgroundColor: Colors.grey.shade800,
              minimumSize: const Size.fromHeight(64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              chatEnabled ? 'Chat Now' : 'Chat unavailable',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (_isBlockedEitherWay) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF171717), borderRadius: BorderRadius.circular(18)),
            child: const Text(
              'This user is unavailable for chat. Manage block/report actions from chat options.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        user.nickname.trim().isEmpty ? 'Unknown User' : user.nickname.trim();

    final displayAge =
        user.age != null && user.age! > 0 ? ', ${user.age}' : '';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _hero(displayName, displayAge),
              const SizedBox(height: 28),
              _infoCard(
                icon: Icons.person,
                title: 'Gender',
                value: user.gender.trim().isEmpty ? 'Not set' : user.gender,
              ),
              if (user.age != null && user.age! > 0)
                _infoCard(
                  icon: Icons.cake_outlined,
                  title: 'Age',
                  value: '${user.age}',
                ),
              _infoCard(
                icon: Icons.favorite_border,
                title: 'Looking For',
                value:
                    user.lookingFor.trim().isEmpty ? 'Not set' : user.lookingFor,
              ),
              _infoCard(
                icon: Icons.location_on_outlined,
                title: 'Location',
                value: _locationText(),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(displayName),
            ],
          ),
        ),
      ),
    );
  }
}