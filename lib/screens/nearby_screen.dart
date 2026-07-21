import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

import '../theme/app_colors.dart';

import '../widgets/empty_nearby_widget.dart';
import '../widgets/nearby_header.dart';
import '../widgets/nearby_section_title.dart';
import '../widgets/nearby_user_card.dart';

import 'chats_screen.dart';
import 'settings_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  AppUser? currentMe;

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

      final result =
          await _userService.getNearbyUsers(currentUser!.uid).first;

      currentMe = await _userService.getUser(currentUser!.uid);

      result.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return a.isOnline ? -1 : 1;
        }

        final aSeen = a.lastSeen ?? DateTime(2000);
        final bSeen = b.lastSeen ?? DateTime(2000);

        return bSeen.compareTo(aSeen);
      });

      if (!mounted) return;

      setState(() {
        users = result;
        isLoading = false;
        isRefreshing = false;
      });
    } catch (_) {
      try {
        final result =
            await _userService.getNearbyUsers(currentUser!.uid).first;

        currentMe = await _userService.getUser(currentUser!.uid);

        result.sort((a, b) {
          if (a.isOnline != b.isOnline) {
            return a.isOnline ? -1 : 1;
          }

          final aSeen = a.lastSeen ?? DateTime(2000);
          final bSeen = b.lastSeen ?? DateTime(2000);

          return bSeen.compareTo(aSeen);
        });

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location update not available right now. Showing available users.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshUsers() async {
    if (!mounted) return;

    setState(() {
      isRefreshing = true;
    });

    await _loadNearbyUsers(showLoader: false);
  }

  Future<String> _distanceText(AppUser user) async {
    if (currentMe == null) {
      return '';
    }

    final distance =
        await _userService.getDistanceBetweenUsers(currentMe!, user);

    if (distance == null) {
      return '';
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(1)} km';
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
          color: AppColors.primary,
        ),
      );
    }

    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyNearbyWidget(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
  NearbyHeader(
    nearbyCount: users.length,
    isRefreshing: isRefreshing,
    onRefresh: _refreshUsers,
  ),

  const SizedBox(height: 24),

  const NearbySectionTitle(
    title: "People Near You",
    icon: Icons.people_alt_rounded,
  ),

  const SizedBox(height: 16),

          ...users.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FutureBuilder<String>(
                future: _distanceText(user),
                builder: (context, snapshot) {
                  return NearbyUserCard(
                    user: user,
                    distanceText: snapshot.data ?? "",
                  );
                },
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
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Nearby",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : _refreshUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
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
            label: "Nearby",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}