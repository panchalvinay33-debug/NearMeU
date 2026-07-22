import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

import '../theme/app_colors.dart';

import '../widgets/empty_nearby_widget.dart';
import '../widgets/nearby_header.dart';
import '../widgets/nearby_section_title.dart';
import '../utils/nearby_filtering.dart';
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
  List<NearbyUserViewData> _visibleUsers = [];
  NearbyFilters _filters = const NearbyFilters();

  bool isLoading = true;
  bool isRefreshing = false;
  bool _loadInProgress = false;
  final Map<String, String> _distanceTextByUserId = <String, String>{};
  final Map<String, double?> _distanceKmByUserId = <String, double?>{};

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

      await _cacheDistances(result);

      if (!mounted) {
        _loadInProgress = false;
        return;
      }

      setState(() {
        users = result;
        _applyFilters();
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

        await _cacheDistances(result);

        if (!mounted) {
          _loadInProgress = false;
          return;
        }

        setState(() {
          users = result;
          _applyFilters();
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

  Future<void> _refreshUsers() async {
    if (!mounted) return;

    setState(() {
      isRefreshing = true;
    });

    await _loadNearbyUsers(showLoader: false);
  }

  void _applyFilters() {
    _visibleUsers = filterAndSortNearbyUsers(
      users: users.map((user) => NearbyUserViewData(
            user: user,
            distanceKm: _distanceKmByUserId[user.uid],
          )),
      filters: _filters,
    );
  }

  Future<void> _cacheDistances(List<AppUser> nearbyUsers) async {
    _distanceTextByUserId.clear();
    _distanceKmByUserId.clear();
    for (final user in nearbyUsers) {
      final distance = await _distanceKm(user);
      _distanceKmByUserId[user.uid] = distance;
      _distanceTextByUserId[user.uid] = _formatDistance(distance);
    }
  }

  Future<double?> _distanceKm(AppUser user) async {
    if (currentMe == null) {
      return null;
    }

    return _userService.getDistanceBetweenUsers(currentMe!, user);
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Distance unavailable';
    if (distance < .05) return 'Very close';
    if (distance < 1) return '${(distance * 1000).round()} m away';
    return '${distance.toStringAsFixed(1)} km away';
  }

  Future<void> _openFilters() async {
    final next = await showModalBottomSheet<NearbyFilters>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => _NearbyFilterSheet(initial: _filters),
    );
    if (next == null || !mounted) return;
    setState(() {
      _filters = next;
      _applyFilters();
    });
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

    if (users.isEmpty || _visibleUsers.isEmpty) {
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
    nearbyCount: _visibleUsers.length,
    isRefreshing: isRefreshing,
    onRefresh: _refreshUsers,
  ),
  if (!_filters.isDefault) _ActiveFilterChips(filters: _filters, onClear: () { setState(() { _filters = const NearbyFilters(); _applyFilters(); }); }),

  const SizedBox(height: 24),

  const NearbySectionTitle(
    title: "People Near You",
    icon: Icons.people_alt_rounded,
  ),

  const SizedBox(height: 16),

          ..._visibleUsers.map(
            (item) { final user = item.user; return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NearbyUserCard(
                user: user,
                distanceText: _distanceTextByUserId[user.uid] ?? "",
              ),
            ); },
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
          IconButton(onPressed: _openFilters, icon: const Icon(Icons.tune_rounded)),
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
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filters, required this.onClear});
  final NearbyFilters filters;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          if (filters.onlineOnly) const Chip(label: Text('Online only')),
          Chip(label: Text('${filters.minDistanceKm.round()}-${filters.maxDistanceKm.round()} km')),
          if (filters.gender != NearbyGenderFilter.all) Chip(label: Text('Gender: ${filters.gender.name}')),
          if (filters.lookingFor != NearbyLookingForFilter.all) Chip(label: Text('Looking: ${filters.lookingFor.name}')),
          if (filters.minAge != 18 || filters.maxAge != 99) Chip(label: Text('${filters.minAge}-${filters.maxAge} yrs')),
          ActionChip(label: const Text('Clear all'), onPressed: onClear),
        ]),
      );
}

class _NearbyFilterSheet extends StatefulWidget {
  const _NearbyFilterSheet({required this.initial});
  final NearbyFilters initial;
  @override
  State<_NearbyFilterSheet> createState() => _NearbyFilterSheetState();
}

class _NearbyFilterSheetState extends State<_NearbyFilterSheet> {
  late NearbyFilters filters = widget.initial;
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Expanded(child: Text('Nearby filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                TextButton(onPressed: () => setState(() => filters = const NearbyFilters()), child: const Text('Clear all')),
              ]),
              SwitchListTile(value: filters.onlineOnly, title: const Text('Online only'), onChanged: (v) => setState(() => filters = filters.copyWith(onlineOnly: v))),
              const SizedBox(height: 8),
              Text('Distance: ${filters.minDistanceKm.round()}-${filters.maxDistanceKm.round()} km'),
              RangeSlider(values: RangeValues(filters.minDistanceKm, filters.maxDistanceKm), min: 0, max: 100, divisions: 20, labels: RangeLabels('${filters.minDistanceKm.round()}', '${filters.maxDistanceKm.round()}'), onChanged: (v) => setState(() => filters = filters.copyWith(minDistanceKm: v.start, maxDistanceKm: v.end))),
              DropdownButtonFormField(value: filters.gender, decoration: const InputDecoration(labelText: 'Gender'), items: NearbyGenderFilter.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name[0].toUpperCase() + v.name.substring(1)))).toList(), onChanged: (v) => setState(() => filters = filters.copyWith(gender: v))),
              DropdownButtonFormField(value: filters.lookingFor, decoration: const InputDecoration(labelText: 'Looking For'), items: NearbyLookingForFilter.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name[0].toUpperCase() + v.name.substring(1)))).toList(), onChanged: (v) => setState(() => filters = filters.copyWith(lookingFor: v))),
              const SizedBox(height: 10),
              Text('Age: ${filters.minAge}-${filters.maxAge}'),
              RangeSlider(values: RangeValues(filters.minAge.toDouble(), filters.maxAge.toDouble()), min: 18, max: 99, divisions: 81, labels: RangeLabels('${filters.minAge}', '${filters.maxAge}'), onChanged: (v) => setState(() => filters = filters.copyWith(minAge: v.start.round(), maxAge: v.end.round()))),
              DropdownButtonFormField(value: filters.sort, decoration: const InputDecoration(labelText: 'Sort'), items: NearbySortMode.values.map((v) => DropdownMenuItem(value: v, child: Text(switch (v) { NearbySortMode.recommended => 'Recommended', NearbySortMode.nearestFirst => 'Nearest first', NearbySortMode.recentlyActive => 'Recently active' }))).toList(), onChanged: (v) => setState(() => filters = filters.copyWith(sort: v))),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context, filters), child: const Text('Apply'))),
            ]),
          ),
        ),
      );
}
