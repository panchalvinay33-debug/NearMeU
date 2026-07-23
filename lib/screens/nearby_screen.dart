import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/discovery_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';
import '../widgets/empty_nearby_widget.dart';
import '../widgets/nearby_header.dart';
import '../widgets/nearby_section_title.dart';
import '../widgets/nearby_user_card.dart';
import '../widgets/unread_nav_icon.dart';
import 'chats_screen.dart';
import 'settings_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _DistanceFilterOption {
  const _DistanceFilterOption({required this.label, this.value});

  final String label;
  final double? value;
}

class _NearbyScreenState extends State<NearbyScreen> {
  final UserService _userService = UserService();
  final DiscoveryService _discoveryService = DiscoveryService();
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  AppUser? currentMe;
  List<AppUser> users = <AppUser>[];
  bool isLoading = true;
  bool isRefreshing = false;
  bool _loadInProgress = false;
  double? _appliedMaxDistanceKm;
  final Map<String, String> _distanceTextByUserId = <String, String>{};

  static const int _minimumDiscoveryTarget = 25;
  static const List<_DistanceFilterOption> _distanceFilterOptions = [
    _DistanceFilterOption(label: 'Any distance'),
    _DistanceFilterOption(label: 'Within 25 km', value: 25),
    _DistanceFilterOption(label: 'Within 50 km', value: 50),
    _DistanceFilterOption(label: 'Within 100 km', value: 100),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadNearbyUsers();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadNearbyUsers({bool showLoader = true}) async {
    if (_loadInProgress) return;
    _loadInProgress = true;

    if (currentUser == null) {
      if (mounted) setState(() => isLoading = false);
      _loadInProgress = false;
      return;
    }

    if (showLoader && mounted) setState(() => isLoading = true);

    try {
      await _userService.updateUserLocation(currentUser!.uid);
      currentMe = await _userService.getUser(currentUser!.uid);
      if (currentMe == null) {
        _applyUsers(const <AppUser>[]);
        return;
      }

      final localUsers = await _userService.getNearbyUsers(currentUser!.uid).first;
      final pool = <String, AppUser>{for (final user in localUsers) user.uid: user};

      if (_appliedMaxDistanceKm == null && pool.length < _minimumDiscoveryTarget) {
        final broadUsers = await _discoveryService
            .watchDiscoveryPool(limit: 100)
            .first;
        for (final user in broadUsers) {
          pool.putIfAbsent(user.uid, () => user);
        }
      }

      final visible = NearbyUserPresenter.selectVisibleUsers(
        currentUser: currentMe!,
        candidates: pool.values,
        maxDistanceKm: _appliedMaxDistanceKm,
        minimumResults: _minimumDiscoveryTarget,
      );
      await _cacheDistances(visible);
      _applyUsers(visible);
    } catch (error, stackTrace) {
      developer.log(
        'Nearby discovery refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh people right now. Please try again.'),
          ),
        );
      }
    } finally {
      _loadInProgress = false;
    }
  }

  void _applyUsers(List<AppUser> value) {
    if (!mounted) return;
    setState(() {
      users = value;
      isLoading = false;
      isRefreshing = false;
    });
  }

  Future<void> _showDistanceFilterSheet() async {
    final selectedOption = await showModalBottomSheet<_DistanceFilterOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xff151515),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x292B0B63),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.tune_rounded, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Choose a distance. Any distance keeps the full discovery feed.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ..._distanceFilterOptions.map((option) {
                  final isSelected = option.value == _appliedMaxDistanceKm;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.pop(sheetContext, option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: .18)
                                : const Color(0xff1b1b1b),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: .09),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (option.value == null)
                                const Icon(
                                  Icons.public_rounded,
                                  color: AppColors.textSecondary,
                                  size: 19,
                                ),
                            ],
                          ),
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
    setState(() => _appliedMaxDistanceKm = selectedOption.value);
    await _loadNearbyUsers(showLoader: false);
  }

  Future<void> _refreshUsers() async {
    if (!mounted) return;
    setState(() => isRefreshing = true);
    await _loadNearbyUsers(showLoader: false);
  }

  Future<void> _cacheDistances(List<AppUser> nearbyUsers) async {
    _distanceTextByUserId.clear();
    for (final user in nearbyUsers) {
      final distance = currentMe == null
          ? null
          : await _userService.getDistanceBetweenUsers(currentMe!, user);
      _distanceTextByUserId[user.uid] =
          NearbyUserPresenter.privacySafeLocationText(
        distanceText: NearbyUserPresenter.distanceText(distance),
        state: user.state,
      );
    }
  }

  List<AppUser> get _visibleUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users.where((user) {
      return user.nickname.toLowerCase().contains(query) ||
          user.state?.toLowerCase().contains(query) == true ||
          user.gender.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search nearby people',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (currentUser == null) {
      return const Center(
        child: Text('User not logged in', style: TextStyle(color: Colors.white)),
      );
    }
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final visibleUsers = _visibleUsers;
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          NearbyHeader(
            nearbyCount: users.length,
            isRefreshing: isRefreshing,
            onRefresh: _refreshUsers,
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
          const SizedBox(height: 20),
          NearbySectionTitle(
            title: _appliedMaxDistanceKm == null
                ? 'People Near You'
                : 'Within ${_appliedMaxDistanceKm!.round()} km',
            icon: Icons.people_alt_rounded,
          ),
          const SizedBox(height: 12),
          if (visibleUsers.isEmpty)
            const EmptyNearbyWidget()
          else
            ...visibleUsers.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NearbyUserCard(
                  user: user,
                  distanceText: _distanceTextByUserId[user.uid],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Nearby',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Nearby filters',
            onPressed: isRefreshing ? null : _showDistanceFilterSheet,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing ? null : _refreshUsers,
            icon: const Icon(Icons.refresh_rounded),
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
      ),
    );
  }
}
