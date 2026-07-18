import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final UserService _userService = UserService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<List<AppUser>> _loadBlockedUsers() async {
    if (currentUser == null) return [];
    return _userService.getBlockedUsers(currentUser!.uid);
  }

  Future<void> _unblockUser(AppUser user) async {
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text(
            'Unblock User',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Do you want to unblock ${user.nickname}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Unblock',
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _userService.unblockUser(
      currentUserId: currentUser!.uid,
      targetUserId: user.uid,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.nickname} unblocked'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {});
  }

  String _locationText(AppUser user) {
    final parts = <String>[];

    if (user.city != null && user.city!.trim().isNotEmpty) {
      parts.add(user.city!.trim());
    }

    if (user.state != null &&
        user.state!.trim().isNotEmpty &&
        user.state!.trim() != user.city?.trim()) {
      parts.add(user.state!.trim());
    }

    if (parts.isEmpty) return 'Location unavailable';
    return parts.join(', ');
  }

  Widget _buildAvatar(AppUser user) {
    final firstLetter =
        user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.purpleAccent,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserTile(AppUser user) {
    final ageText = user.age != null && user.age! > 0 ? ', ${user.age}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(user),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.nickname}$ageText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _locationText(user),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => _unblockUser(user),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.purpleAccent),
              foregroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            child: const Text(
              'Unblock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _loadBlockedUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final blockedUsers = snapshot.data ?? [];

          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text(
                'No blocked users',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.purpleAccent,
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: blockedUsers.map(_buildUserTile).toList(),
            ),
          );
        },
      ),
    );
  }
}