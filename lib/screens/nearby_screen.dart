import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';
import '../widgets/chat_tab_badge.dart';
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
  final Map<String, String> _distanceTextByUserId = <String, String>{};

  StreamSubscription<List<AppUser>>? _nearbySubscription;
  AppUser? _currentMe;
  List<AppUser> _allCandidates = <AppUser>[];
  List<AppUser> _visibleUsers = <AppUser>[];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _onlineOnly = false;
  double? _maxDistanceKm;
  String _gender = 'All';
  String _lookingFor = 'All';
  RangeValues _ageRange = const RangeValues(18, 99);
  String _sort = 'Recommended';

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _startRealtimeDirectory();
  }

  @override
  void dispose() {
    _nearbySubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRealtimeDirectory() async {
    final currentUser = _firebaseUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      await _userService.updateUserLocation(currentUser.uid);
    } catch (error) {
      developer.log('Nearby location refresh failed', error: error);
    }

    await _nearbySubscription?.cancel();
    _nearbySubscription = _userService
        .getNearbyUsers(currentUser.uid)
        .listen(
      (candidates) async {
        try {
          final me = await _userService.getUser(currentUser.uid);
          if (!mounted) return;

          _currentMe = me;
          _allCandidates = List<AppUser>.from(candidates);
          await _applyFiltersAndSort();
        } catch (error) {
          developer.log('Nearby realtime refresh failed', error: error);
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isRefreshing = false;
            });
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Nearby stream failed',
          error: error,
          stackTrace: stackTrace,
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      },
    );
  }

  Future<void> _applyFiltersAndSort() async {
    final me = _currentMe;
    if (me == null) {
      if (mounted) {
        setState(() {
          _visibleUsers = <AppUser>[];
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      return;
    }

    final users = NearbyUserPresenter.filterEligibleUsers(
      currentUser: me,
      candidates: _allCandidates,
      maxDistanceKm: _maxDistanceKm,
      onlineOnly: _onlineOnly,
      gender: _gender,
      lookingFor: _lookingFor,
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
    );

    switch (_sort) {
      case 'Nearest first':
        NearbyUserPresenter.sortNearestFirst(currentUser: me, users: users);
        break;
      case 'Recently active':
        users.sort(NearbyUserPresenter.sortRecentlyActive);
        break;
      default:
        NearbyUserPresenter.sortUsers(currentUser: me, users: users);
    }

    _distanceTextByUserId.clear();
    for (final user in users) {
      final distance = await _userService.getDistanceBetweenUsers(me, user);
      _distanceTextByUserId[user.uid] =
          NearbyUserPresenter.privacySafeLocationText(
        distanceText: NearbyUserPresenter.distanceText(distance),
        state: user.state,
      );
    }

    if (!mounted) return;
    setState(() {
      _visibleUsers = users;
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  bool get _hasActiveFilters =>
      _onlineOnly ||
      _maxDistanceKm != null ||
      _gender != 'All' ||
      _lookingFor != 'All' ||
      _ageRange.start.round() != 18 ||
      _ageRange.end.round() != 99 ||
      _sort != 'Recommended';

  Future<void> _refreshUsers() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    final currentUser = _firebaseUser;
    if (currentUser != null) {
      try {
        await _userService.updateUserLocation(currentUser.uid);
        _currentMe = await _userService.getUser(currentUser.uid);
      } catch (error) {
        developer.log('Manual Nearby refresh failed', error: error);
      }
    }

    await _applyFiltersAndSort();
  }

  Future<void> _clearAllFilters() async {
    setState(() {
      _onlineOnly = false;
      _maxDistanceKm = null;
      _gender = 'All';
      _lookingFor = 'All';
      _ageRange = const RangeValues(18, 99);
      _sort = 'Recommended';
    });
    await _applyFiltersAndSort();
  }

  Future<void> _openFilterSheet() async {
    var onlineOnly = _onlineOnly;
    var distance = _maxDistanceKm;
    var gender = _gender;
    var lookingFor = _lookingFor;
    var ageRange = _ageRange;
    var sort = _sort;

    final apply = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nearby filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close filters',
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Online only',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: onlineOnly,
                    activeColor: AppColors.primary,
                    onChanged: (value) =>
                        setSheetState(() => onlineOnly = value),
                  ),
                  _FilterDropdown<double?>(
                    label: 'Distance',
                    value: distance,
                    items: const <double?, String>{
                      null: 'Any distance',
                      25: 'Within 25 km',
                      50: 'Within 50 km',
                      100: 'Within 100 km',
                    },
                    onChanged: (value) =>
                        setSheetState(() => distance = value),
                  ),
                  _FilterDropdown<String>(
                    label: 'Gender',
                    value: gender,
                    items: const <String, String>{
                      'All': 'All',
                      'Male': 'Male',
                      'Female': 'Female',
                      'Other': 'Other',
                    },
                    onChanged: (value) =>
                        setSheetState(() => gender = value ?? 'All'),
                  ),
                  _FilterDropdown<String>(
                    label: 'Looking For',
                    value: lookingFor,
                    items: const <String, String>{
                      'All': 'All',
                      'Male': 'Male',
                      'Female': 'Female',
                      'Both': 'Both',
                    },
                    onChanged: (value) =>
                        setSheetState(() => lookingFor = value ?? 'All'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Age range ${ageRange.start.round()}–${ageRange.end.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  RangeSlider(
                    values: ageRange,
                    min: 18,
                    max: 99,
                    divisions: 81,
                    activeColor: AppColors.primary,
                    labels: RangeLabels(
                      '${ageRange.start.round()}',
                      '${ageRange.end.round()}',
                    ),
                    onChanged: (value) =>
                        setSheetState(() => ageRange = value),
                  ),
                  _FilterDropdown<String>(
                    label: 'Sort',
                    value: sort,
                    items: const <String, String>{
                      'Recommended': 'Recommended',
                      'Nearest first': 'Nearest first',
                      'Recently active': 'Recently active',
                    },
                    onChanged: (value) =>
                        setSheetState(() => sort = value ?? 'Recommended'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              onlineOnly = false;
                              distance = null;
                              gender = 'All';
                              lookingFor = 'All';
                              ageRange = const RangeValues(18, 99);
                              sort = 'Recommended';
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (apply != true || !mounted) return;
    setState(() {
      _onlineOnly = onlineOnly;
      _maxDistanceKm = distance;
      _gender = gender;
      _lookingFor = lookingFor;
      _ageRange = ageRange;
      _sort = sort;
    });
    await _applyFiltersAndSort();
  }

  Widget _body() {
    if (_firebaseUser == null) {
      return const Center(child: Text('User not logged in'));
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_visibleUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 100), EmptyNearbyWidget()],
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
            nearbyCount: _visibleUsers.length,
            isRefreshing: _isRefreshing,
            onRefresh: _refreshUsers,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_onlineOnly) const Chip(label: Text('Online only')),
                if (_maxDistanceKm != null)
                  Chip(
                    label: Text('Within ${_maxDistanceKm!.round()} km'),
                  ),
                if (_gender != 'All') Chip(label: Text('Gender: $_gender')),
                if (_lookingFor != 'All')
                  Chip(label: Text('Looking for: $_lookingFor')),
                if (_ageRange.start.round() != 18 ||
                    _ageRange.end.round() != 99)
                  Chip(
                    label: Text(
                      'Ages ${_ageRange.start.round()}–${_ageRange.end.round()}',
                    ),
                  ),
                if (_sort != 'Recommended') Chip(label: Text(_sort)),
                ActionChip(
                  label: const Text('Clear All'),
                  onPressed: _clearAllFilters,
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const NearbySectionTitle(
            title: 'People Near You',
            icon: Icons.people_alt_rounded,
          ),
          const SizedBox(height: 16),
          ..._visibleUsers.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NearbyUserCard(
                user: user,
                distanceText: _distanceTextByUserId[user.uid] ??
                    'Distance unavailable',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseUser;

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
            tooltip: 'Open filters',
            onPressed: _openFilterSheet,
            icon: Icon(_hasActiveFilters ? Icons.filter_alt : Icons.tune),
          ),
          IconButton(
            tooltip: 'Refresh nearby users',
            onPressed: _isRefreshing ? null : _refreshUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _body(),
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
            icon: currentUser == null
                ? const Icon(Icons.chat_bubble_outline)
                : ChatTabBadge(userId: currentUser.uid),
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

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: AppColors.surface,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
