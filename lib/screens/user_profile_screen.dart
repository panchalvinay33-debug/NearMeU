import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

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
      final blockedEitherWay = await _userService.isBlockedEitherWay(
        currentUserId: currentUser!.uid,
        otherUserId: user.uid,
      );

      if (!mounted) return;
      setState(() {
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
    return UserAvatar(user: user, radius: 70);
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatScreen(otherUserId: user.uid, otherUserName: displayName),
      ),
    );
  }

  Widget _buildActionButtons(String displayName) {
    if (_isLoadingBlockState) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final interactionEnabled = !_isBlockedEitherWay;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: interactionEnabled ? () => _openChat(displayName) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: interactionEnabled
                  ? AppColors.primary
                  : Colors.grey.shade800,
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor: AppColors.textSecondary,
              disabledBackgroundColor: Colors.grey.shade800,
              minimumSize: const Size.fromHeight(64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              interactionEnabled ? 'Chat Now' : 'Chat unavailable',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (_isBlockedEitherWay) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'This user is unavailable for chat or calls.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
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
    final displayName = user.nickname.trim().isEmpty
        ? 'Unknown User'
        : user.nickname.trim();

    final displayAge = user.age != null && user.age! > 0 ? ', ${user.age}' : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
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
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _locationText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textHint,
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
                value: user.lookingFor.trim().isEmpty
                    ? 'Not set'
                    : user.lookingFor,
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
