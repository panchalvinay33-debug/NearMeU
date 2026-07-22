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

class _DistanceFilterOption {
  _DistanceFilterOption({required this.label, required this.value});

  final String label;
  final double? value;
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

  final List<_DistanceFilterOption> _distanceFilterOptions = [
    _DistanceFilterOption(label: 'Any distance', value: null),
    _DistanceFilterOption(label: 'Within 25 km', value: 25),
    _DistanceFilterOption(label: 'Within 50 km', value: 50),
    _DistanceFilterOption(label: 'Within 100 km', value: 100),
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

      final result = await _userService.getNearbyUsers(currentUser!.uid).first;

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
        final result = await _userService.getNearbyUsers(currentUser!.uid).first;

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

  Future<void> _showDistanceFilterSheet() async {
    final selectedOption = await showModalBottomSheet<_DistanceFilterOption>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nearby filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how far away people can be. Any distance keeps all eligible users visible.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                ..._distanceFilterOptions.map((option) {
                  final isSelected = option.value == _appliedMaxDistanceKm;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(context, option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: .18)
                              : const Color(0xff171717),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedOption == null) return;
    await _applyDistanceFilter(selectedOption.value);
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
          IconButton(
            tooltip: 'Distance filter',
            onPressed: isRefreshing ? null : _showDistanceFilterSheet,
            icon: const Icon(Icons.tune),
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