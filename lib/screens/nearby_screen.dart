import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';
import 'chats_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';

class NearbyScreen extends StatefulWidget {
  NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<AppUser> users = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  Future<void> _loadNearbyUsers({bool showLoader = true}) async {
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (showLoader) {
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });
    }

    try {
      await _userService.updateUserLocation(currentUser!.uid);

      final result = await _userService.getNearbyUsers(currentUser!.uid).first;

      if (!mounted) return;

      setState(() {
        users = result;
        isLoading = false;
        isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;

      try {
        final result = await _userService.getNearbyUsers(currentUser!.uid).first;

        if (!mounted) return;

        setState(() {
          users = result;
          isLoading = false;
          isRefreshing = false;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          users = [];
          isLoading = false;
          isRefreshing = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location update not available right now. Showing available users.',
          ),
        ),
      );
    }
  }

  Future<void> _refreshUsers() async {
    if (!mounted) return;

    setState(() {
      isRefreshing = true;
    });

    await _loadNearbyUsers(showLoader: false);
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

  Future<String> _distanceText(AppUser user) async {
    if (currentUser == null) return 'Distance unavailable';

    final me = await _userService.getUser(currentUser!.uid);
    if (me == null) return 'Distance unavailable';

    final distance = await _userService.getDistanceBetweenUsers(me, user);

    if (distance == null) return 'Distance unavailable';

    if (distance < 1) {
      final meters = (distance * 1000).round();
      return '$meters m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

  Widget _buildAvatar(AppUser user) {
    final firstLetter =
        user.nickname.trim().isNotEmpty ? user.nickname[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 34,
      backgroundColor: Colors.purpleAccent,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final displayName =
        user.nickname.trim().isEmpty ? 'Unknown User' : user.nickname.trim();

    final ageText = user.age != null && user.age! > 0 ? ', ${user.age}' : '';
    final genderText =
        user.gender.trim().isEmpty ? 'Not set' : user.gender.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: user),
            ),
          );

          if (result == true) {
            await _refreshUsers();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(user),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName$ageText',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      genderText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _locationText(user),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: _distanceText(user),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Checking distance...',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: user.uid,
                        otherUserName: displayName,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.purpleAccent,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          'User not logged in',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.purpleAccent,
        ),
      );
    }

    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        color: Colors.purpleAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.location_searching,
              color: Colors.white38,
              size: 62,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No nearby users found yet',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Pull down to refresh and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: Colors.purpleAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(users[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xff0B0B0B),
        elevation: 0,
        title: const Text(
          'Nearby',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : _refreshUsers,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}