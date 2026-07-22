import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';

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
  bool _loadInProgress = false;
  final Map<String, String> _distanceTextByUserId = <String, String>{};
  double? _appliedMaxDistanceKm;

  static final List<PopupMenuEntry<double?>> _distanceFilterItems =
      <PopupMenuEntry<double?>>[
    const PopupMenuItem<double?>(
      value: null,
      child: Text('Any distance'),
    ),
    const PopupMenuItem<double?>(
      value: 25.0,
      child: Text('Within 25 km'),
    ),
    const PopupMenuItem<double?>(
      value: 50.0,
      child: Text('Within 50 km'),
    ),
    const PopupMenuItem<double?>(
      value: 100.0,
      child: Text('Within 100 km'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  Future<void> _loadNearbyUsers({bool showLoader = true}) async {
    if (_loadInProgress) return;
    _loadInProgress = true;

    if (currentUser == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _loadInProgress = false;
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
      if (currentMe == null) {
        result.clear();
      } else {
        final filtered = NearbyUserPresenter.filterEligibleUsers(
          currentUser: currentMe!,
          candidates: result,
          maxDistanceKm: _appliedMaxDistanceKm,
        );
        result
          ..clear()
          ..addAll(filtered);
        await _cacheDistances(result);
        NearbyUserPresenter.sortUsers(currentUser: currentMe!, users: result);
      }

      if (!mounted) {
        _loadInProgress = false;
        return;
      }

      setState(() {
        users = result;
        isLoading = false;
        isRefreshing = false;
      });
      _loadInProgress = false;
    } catch (error) {
      developer.log(
        'Location refresh failed; loading cached nearby users',
        error: error,
      );
      try {
        final result =
            await _userService.getNearbyUsers(currentUser!.uid).first;

        currentMe = await _userService.getUser(currentUser!.uid);
        if (currentMe == null) {
          result.clear();
        } else {
          final filtered = NearbyUserPresenter.filterEligibleUsers(
            currentUser: currentMe!,
            candidates: result,
            maxDistanceKm: _appliedMaxDistanceKm,
          );
          result
            ..clear()
            ..addAll(filtered);
          await _cacheDistances(result);
          NearbyUserPresenter.sortUsers(currentUser: currentMe!, users: result);
        }

        if (!mounted) {
          _loadInProgress = false;
          return;
        }

        setState(() {
          users = result;
          isLoading = false;
          isRefreshing = false;
        });
        _loadInProgress = false;
      } catch (error) {
        developer.log('Nearby fallback load failed', error: error);
        if (!mounted) {
          _loadInProgress = false;
          return;
        }

        setState(() {
          users = [];
          isLoading = false;
          isRefreshing = false;
        });
        _loadInProgress = false;
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

  Future<void> _applyDistanceFilter(double? maxDistanceKm) async {
    setState(() {
      _appliedMaxDistanceKm = maxDistanceKm;
    });
    await _loadNearbyUsers(showLoader: false);
  }

  Future<void> _refreshUsers() async {
    if (!mounted) return;

    setState(() {
      isRefreshing = true;
    });

    await _loadNearbyUsers(showLoader: false);
  }

  Future<void> _cacheDistances(List<AppUser> nearbyUsers) async {
    _distanceTextByUserId.clear();
    for (final user in nearbyUsers) {
      _distanceTextByUserId[user.uid] = await _distanceText(user);
    }
  }

  Future<String> _distanceText(AppUser user) async {
    if (currentMe == null) {
      return NearbyUserPresenter.privacySafeLocationText(
        distanceText: 'Distance unavailable',
        state: user.state,
      );
    }

    final distance = await _userService.getDistanceBetweenUsers(currentMe!, user);
    return NearbyUserPresenter.privacySafeLocationText(
      distanceText: NearbyUserPresenter.distanceText(distance),
      state: user.state,
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
              child: NearbyUserCard(
                user: user,
                distanceText: _distanceTextByUserId[user.uid] ?? "",
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
          PopupMenuButton<double?>(
            tooltip: 'Distance filter',
            icon: const Icon(Icons.tune),
            initialValue: _appliedMaxDistanceKm,
            onSelected: _applyDistanceFilter,
            itemBuilder: (context) => _distanceFilterItems,
          ),
          IconButton(
            tooltip: 'Clear all filters',
            onPressed: isRefreshing ? null : () => _applyDistanceFilter(null),
            icon: const Icon(Icons.filter_alt_off),
          ),
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
