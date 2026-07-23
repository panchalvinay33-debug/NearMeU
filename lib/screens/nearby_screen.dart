import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';
import '../widgets/nearby_header.dart';
import '../widgets/nearby_user_card.dart';
import '../widgets/unread_nav_icon.dart';
import 'chats_screen.dart';
import 'settings_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  AppUser? currentMe;
  List<AppUser> _allEligibleUsers = <AppUser>[];
  List<AppUser> users = <AppUser>[];

  final Map<String, double?> _distanceKmByUserId = <String, double?>{};
  final Map<String, String> _distanceTextByUserId = <String, String>{};

  bool isLoading = true;
  bool isRefreshing = false;
  bool _loadInProgress = false;
  bool _reloadRequested = false;

  // null means "Any distance". This is the default so offline users still
  // remain visible when there are no online users nearby.
  double? _maxDistanceKm;
  String _genderFilter = 'All';
  String _activityFilter = 'All';
  String _searchQuery = '';

  String get _distanceLabel {
    final distance = _maxDistanceKm;
    return distance == null ? 'Any distance' : 'Within ${distance.round()} km';
  }

  bool get _hasActiveFilters {
    return _maxDistanceKm != null ||
        _genderFilter != 'All' ||
        _activityFilter != 'All' ||
        _searchQuery.isNotEmpty;
  }

  int get _onlineCount {
    return users.where(NearbyUserPresenter.isEffectivelyOnline).length;
  }

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyUsers({bool showLoader = true}) async {
    if (_loadInProgress) {
      _reloadRequested = true;
      return;
    }

    _loadInProgress = true;

    if (currentUser == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
      _loadInProgress = false;
      return;
    }

    if (showLoader && mounted) {
      setState(() => isLoading = true);
    }

    try {
      await _userService.updateUserLocation(currentUser!.uid);
      await _readNearbyCandidates();
    } catch (error, stackTrace) {
      developer.log(
        'Location refresh failed; loading cached nearby users',
        error: error,
        stackTrace: stackTrace,
      );

      try {
        await _readNearbyCandidates();
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Location refresh was unavailable. Showing cached people.',
                ),
              ),
            );
        }
      } catch (fallbackError, fallbackStackTrace) {
        developer.log(
          'Nearby fallback load failed',
          error: fallbackError,
          stackTrace: fallbackStackTrace,
        );

        if (mounted) {
          setState(() {
            _allEligibleUsers = <AppUser>[];
            users = <AppUser>[];
            isLoading = false;
            isRefreshing = false;
          });
        }
      }
    } finally {
      final shouldReload = _reloadRequested;
      _reloadRequested = false;
      _loadInProgress = false;

      if (shouldReload && mounted) {
        await _loadNearbyUsers(showLoader: false);
      }
    }
  }

  Future<void> _readNearbyCandidates() async {
    final result = await _userService.getNearbyUsers(currentUser!.uid).first;
    final me = await _userService.getUser(currentUser!.uid);

    if (me == null) {
      if (!mounted) return;
      setState(() {
        currentMe = null;
        _allEligibleUsers = <AppUser>[];
        users = <AppUser>[];
        isLoading = false;
        isRefreshing = false;
      });
      return;
    }

    final eligible = NearbyUserPresenter.filterEligibleUsers(
      currentUser: me,
      candidates: result,
      maxDistanceKm: null,
    );

    _cacheDistances(me, eligible);
    final visible = _buildVisibleUsers(me, eligible);

    if (!mounted) return;
    setState(() {
      currentMe = me;
      _allEligibleUsers = eligible;
      users = visible;
      isLoading = false;
      isRefreshing = false;
    });
  }

  void _cacheDistances(AppUser me, Iterable<AppUser> candidates) {
    _distanceKmByUserId.clear();
    _distanceTextByUserId.clear();

    for (final user in candidates) {
      final distance = NearbyUserPresenter.distanceKm(me, user);
      _distanceKmByUserId[user.uid] = distance;
      _distanceTextByUserId[user.uid] =
          NearbyUserPresenter.privacySafeLocationText(
            distanceText: NearbyUserPresenter.distanceText(distance),
            state: user.state,
          );
    }
  }

  List<AppUser> _buildVisibleUsers(AppUser me, Iterable<AppUser> candidates) {
    final query = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();

    final filtered = candidates.where((user) {
      final maxDistance = _maxDistanceKm;
      if (maxDistance != null) {
        final distance = _distanceKmByUserId[user.uid];
        if (distance == null || distance > maxDistance) return false;
      }

      if (_genderFilter != 'All' && user.gender != _genderFilter) {
        return false;
      }

      if (_activityFilter == 'Online' &&
          !NearbyUserPresenter.isEffectivelyOnline(user, now: now)) {
        return false;
      }

      if (_activityFilter == 'Recent' &&
          !NearbyUserPresenter.wasRecentlyActive(user, now: now)) {
        return false;
      }

      if (query.isNotEmpty) {
        final searchable = <String>[
          user.nickname,
          user.gender,
          user.state ?? '',
          user.country ?? '',
        ].join(' ').toLowerCase();

        if (!searchable.contains(query)) return false;
      }

      return true;
    }).toList();

    NearbyUserPresenter.sortUsers(currentUser: me, users: filtered);

    return filtered;
  }

  void _applyVisibleFilters() {
    final me = currentMe;
    if (me == null || !mounted) return;

    setState(() {
      users = _buildVisibleUsers(me, _allEligibleUsers);
    });
  }

  Future<void> _refreshUsers() async {
    if (!mounted) return;
    setState(() => isRefreshing = true);
    await _loadNearbyUsers(showLoader: false);
  }

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      _maxDistanceKm = null;
      _genderFilter = 'All';
      _activityFilter = 'All';
      _searchQuery = '';
      final me = currentMe;
      users = me == null
          ? <AppUser>[]
          : _buildVisibleUsers(me, _allEligibleUsers);
    });
  }

  Future<void> _showFilters() async {
    var anyDistance = _maxDistanceKm == null;
    var selectedDistance = _maxDistanceKm ?? AppConstants.maximumNearbyRadiusKm;
    var selectedGender = _genderFilter;
    var selectedActivity = _activityFilter;

    final result = await showModalBottomSheet<_NearbyFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget choiceChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
              IconData? icon,
            }) {
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => onTap(),
                avatar: icon == null
                    ? null
                    : Icon(
                        icon,
                        size: 17,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                label: Text(label),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceLight,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.cardBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Discover Filters',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose distance, profile type and activity.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FilterPanel(
                      title: 'Distance range',
                      icon: Icons.route_rounded,
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: anyDistance,
                            activeColor: AppColors.primary,
                            title: const Text(
                              'Any distance',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: const Text(
                              'Show every eligible person in the discovery area.',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setModalState(() => anyDistance = value);
                            },
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text(
                                '5 km',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: selectedDistance
                                      .clamp(
                                        5,
                                        AppConstants.maximumNearbyRadiusKm,
                                      )
                                      .toDouble(),
                                  min: 5,
                                  max: AppConstants.maximumNearbyRadiusKm,
                                  divisions: 19,
                                  label: '${selectedDistance.round()} km',
                                  activeColor: AppColors.primary,
                                  inactiveColor: AppColors.divider,
                                  onChanged: anyDistance
                                      ? null
                                      : (value) {
                                          setModalState(() {
                                            selectedDistance = value;
                                          });
                                        },
                                ),
                              ),
                              Text(
                                '${AppConstants.maximumNearbyRadiusKm.round()} km',
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              anyDistance
                                  ? 'Currently: Any distance'
                                  : 'Currently: Within ${selectedDistance.round()} km',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterPanel(
                      title: 'Show profiles',
                      icon: Icons.people_alt_rounded,
                      child: Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          choiceChip(
                            label: 'All',
                            selected: selectedGender == 'All',
                            icon: Icons.groups_rounded,
                            onTap: () {
                              setModalState(() => selectedGender = 'All');
                            },
                          ),
                          choiceChip(
                            label: 'Male',
                            selected: selectedGender == 'Male',
                            icon: Icons.male_rounded,
                            onTap: () {
                              setModalState(() => selectedGender = 'Male');
                            },
                          ),
                          choiceChip(
                            label: 'Female',
                            selected: selectedGender == 'Female',
                            icon: Icons.female_rounded,
                            onTap: () {
                              setModalState(() => selectedGender = 'Female');
                            },
                          ),
                          choiceChip(
                            label: 'Other',
                            selected: selectedGender == 'Other',
                            icon: Icons.person_rounded,
                            onTap: () {
                              setModalState(() => selectedGender = 'Other');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterPanel(
                      title: 'Activity',
                      icon: Icons.bolt_rounded,
                      child: Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          choiceChip(
                            label: 'All users',
                            selected: selectedActivity == 'All',
                            icon: Icons.public_rounded,
                            onTap: () {
                              setModalState(() => selectedActivity = 'All');
                            },
                          ),
                          choiceChip(
                            label: 'Online now',
                            selected: selectedActivity == 'Online',
                            icon: Icons.circle,
                            onTap: () {
                              setModalState(() => selectedActivity = 'Online');
                            },
                          ),
                          choiceChip(
                            label: 'Recently active',
                            selected: selectedActivity == 'Recent',
                            icon: Icons.schedule_rounded,
                            onTap: () {
                              setModalState(() => selectedActivity = 'Recent');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                const _NearbyFilterResult(
                                  maxDistanceKm: null,
                                  gender: 'All',
                                  activity: 'All',
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                color: AppColors.cardBorder,
                              ),
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                _NearbyFilterResult(
                                  maxDistanceKm: anyDistance
                                      ? null
                                      : selectedDistance,
                                  gender: selectedGender,
                                  activity: selectedActivity,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Apply Filters'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _maxDistanceKm = result.maxDistanceKm;
      _genderFilter = result.gender;
      _activityFilter = result.activity;
    });
    _applyVisibleFilters();
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by name, gender or state',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryLight,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? IconButton(
                  tooltip: 'Filters',
                  onPressed: _showFilters,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.textSecondary,
                  ),
                )
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _applyVisibleFilters();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          _searchQuery = value.trim().toLowerCase();
          _applyVisibleFilters();
        },
      ),
    );
  }

  Widget _buildFilterSummary() {
    final labels = <String>[
      if (_maxDistanceKm != null) 'Within ${_maxDistanceKm!.round()} km',
      if (_genderFilter != 'All') _genderFilter,
      if (_activityFilter == 'Online') 'Online now',
      if (_activityFilter == 'Recent') 'Recently active',
      if (_searchQuery.isNotEmpty) 'Search: ${_searchController.text.trim()}',
    ];

    if (labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...labels.map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: _resetFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: AppColors.primaryLight,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No matching people found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Offline users are included by default. Try Any distance, clear filters, or refresh location.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Clear filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _refreshUsers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          'User not logged in',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          NearbyHeader(
            nearbyCount: users.length,
            onlineCount: _onlineCount,
            distanceLabel: _distanceLabel,
            isRefreshing: isRefreshing,
            onRefresh: _refreshUsers,
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
          _buildFilterSummary(),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.primaryLight,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'People Near You',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${users.length}',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (users.isEmpty)
            _buildEmptyState()
          else
            ...users.map(
              (user) => NearbyUserCard(
                user: user,
                distanceText: _distanceTextByUserId[user.uid] ?? '',
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
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Premium filters',
            onPressed: _showFilters,
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          if (_hasActiveFilters)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: _resetFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
            ),
          IconButton(
            tooltip: 'Refresh nearby users',
            onPressed: isRefreshing ? null : _refreshUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.location_on_rounded),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: UnreadNavIcon(
              userId: uid,
              icon: Icons.chat_bubble_outline_rounded,
            ),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _NearbyFilterResult {
  final double? maxDistanceKm;
  final String gender;
  final String activity;

  const _NearbyFilterResult({
    required this.maxDistanceKm,
    required this.gender,
    required this.activity,
  });
}

class _FilterPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}
