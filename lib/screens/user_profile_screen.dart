import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();

  bool _isLoadingBlockState = true;
  bool _isBlockedEitherWay = false;
  bool _blockedByMe = false;
  bool _actionLoading = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;
  AppUser get user => widget.user;

  @override
  void initState() {
    super.initState();
    _loadBlockState();
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
        _blockedByMe = blockedByMe;
        _isBlockedEitherWay = blockedEitherWay;
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

  Future<void> _blockUser() async {
    if (currentUser == null || _actionLoading) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Block user?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Blocked user nearby list aur chat access se hide ho jayega.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await _userService.blockUser(
        currentUserId: currentUser!.uid,
        targetUserId: user.uid,
      );

      if (!mounted) return;

      setState(() {
        _blockedByMe = true;
        _isBlockedEitherWay = true;
        _actionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User blocked'),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _actionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to block user'),
        ),
      );
    }
  }

  Future<void> _unblockUser() async {
    if (currentUser == null || _actionLoading) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await _userService.unblockUser(
        currentUserId: currentUser!.uid,
        targetUserId: user.uid,
      );

      if (!mounted) return;

      setState(() {
        _blockedByMe = false;
        _isBlockedEitherWay = false;
        _actionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User unblocked'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _actionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to unblock user'),
        ),
      );
    }
  }

  Widget _buildActionButtons(String displayName) {
    if (_isLoadingBlockState) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: CircularProgressIndicator(
          color: Colors.purpleAccent,
        ),
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
              backgroundColor:
                  chatEnabled ? Colors.purpleAccent : Colors.grey.shade800,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              disabledBackgroundColor: Colors.grey.shade800,
              minimumSize: const Size.fromHeight(64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              chatEnabled ? 'Chat Now' : 'Chat unavailable',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _actionLoading
                ? null
                : _blockedByMe
                    ? _unblockUser
                    : _blockUser,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  _blockedByMe ? Colors.greenAccent : Colors.redAccent,
              side: BorderSide(
                color: _blockedByMe ? Colors.greenAccent : Colors.redAccent,
              ),
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: _actionLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _blockedByMe ? Icons.lock_open : Icons.block,
                  ),
            label: Text(
              _blockedByMe ? 'Unblock User' : 'Block User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_isBlockedEitherWay) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _blockedByMe
                  ? 'This user is blocked. Nearby/chat access restricted.'
                  : 'This user is unavailable for chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildAvatar(),
              const SizedBox(height: 24),
              Text(
                '$displayName$displayAge',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _locationText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
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