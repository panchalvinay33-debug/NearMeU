import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/resilient_nearby_service.dart';
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
  final ResilientNearbyService _nearbyService = ResilientNearbyService();
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  AppUser? _currentProfile;
  List<AppUser> _allCandidates = const <AppUser>[];
  List<AppUser> _visibleUsers = const <AppUser>[];
  final Map<String, double?> _distanceByUserId = <String, double?>{};

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showingSavedSnapshot = false;
  String? _errorMessage;
  double? _maximumDistanceKm;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadNearby(refreshLocation: true);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_applyFilters)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadNearby({required bool refreshLocation}) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = 'Please sign in again.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        if (_currentProfile == null) _isLoading = true;
        _isRefreshing = _currentProfile != null;
        _errorMessage = null;
      });
    }

    var locationRefreshFailed = false;
    try {
      if (refreshLocation) {
        try {
          await _userService.updateUserLocation(uid);
        } catch (error, stackTrace) {
          locationRefreshFailed = true;
          developer.log(
            'Location refresh unavailable; retaining last saved location',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      final results = await Future.wait<Object?>([
        _userService.getUser(uid),
        _nearbyService.loadCandidates(),
      ]);
      final profile = results[0] as AppUser?;
      final nearbyResult = results[1] as NearbyLoadResult;

      if (!mounted) return;
      setState(() {
        _currentProfile = profile;
        _allCandidates = nearbyResult.users;
        _showingSavedSnapshot = nearbyResult.fromCache;
        _isLoading = false;
        _isRefreshing = false;
      });
      _applyFilters();

      if (locationRefreshFailed && mounted && !nearbyResult.fromCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location refresh was unavailable. Showing people using your last saved location.',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Nearby candidates could not be loaded',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage =
            'Could not load people right now. Check your connection and retry.';
      });
    }
  }

  void _applyFilters() {
    final profile = _currentProfile;
    if (profile == null || !mounted) return;

    final query = _searchController.text.trim().toLowerCase();
    final eligible = NearbyUserPresenter.filterEligibleUsers(
      currentUser: profile,
      candidates: _allCandidates,
      maxDistanceKm: _maximumDistanceKm,
    );

    final filtered = eligible.where((candidate) {
      if (query.isEmpty) return true;
      return candidate.nickname.toLowerCase().contains(query) ||
          candidate.gender.toLowerCase().contains(query) ||
          (candidate.state?.toLowerCase().contains(query) ?? false) ||
          (candidate.country?.toLowerCase().contains(query) ?? false);
    }).toList();

    NearbyUserPresenter.sortUsers(currentUser: profile, users: filtered);
    _distanceByUserId
      ..clear()
      ..addEntries(
        filtered.map(
          (candidate) => MapEntry(
            candidate.uid,
            NearbyUserPresenter.distanceKm(profile, candidate),
          ),
        ),
      );

    setState(() => _visibleUsers = filtered);
  }

  Future<void> _showDistanceFilter() async {
    final selected = await showModalBottomSheet<double?>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        Widget choice(String title, double? value) {
          final isSelected = _maximumDistanceKm == value;
          return ListTile(
            leading: Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : Colors.white54,
            ),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, value ?? -1),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Maximum distance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                choice('Any distance', null),
                choice('Within 25 km', 25),
                choice('Within 50 km', 50),
                choice('Within 100 km', 100),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() => _maximumDistanceKm = selected < 0 ? null : selected);
    _applyFilters();
  }

  String get _distanceLabel {
    final distance = _maximumDistanceKm;
    return distance == null ? 'Any distance' : 'Within ${distance.round()} km';
  }

  int get _onlineCount =>
      _visibleUsers.where(NearbyUserPresenter.isEffectivelyOnline).length;

  @override
  Widget build(BuildContext context) {
    final uid = currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Nearby',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Distance filter',
            onPressed: _showDistanceFilter,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isRefreshing
                ? null
                : () => _loadNearby(refreshLocation: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white54,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null && _allCandidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 58,
                color: AppColors.primary,
              ),
              const SizedBox(height: 18),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _loadNearby(refreshLocation: false),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNearby(refreshLocation: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          NearbyHeader(
            nearbyCount: _visibleUsers.length,
            onlineCount: _onlineCount,
            distanceLabel: _distanceLabel,
            isRefreshing: _isRefreshing,
            onRefresh: () => _loadNearby(refreshLocation: true),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name, gender or state',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Distance filter',
                onPressed: _showDistanceFilter,
                icon: const Icon(Icons.tune_rounded),
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_showingSavedSnapshot) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_bolt_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connection unavailable. Showing your last saved Nearby list.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'People Near You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_visibleUsers.length}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_visibleUsers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_search_rounded,
                    size: 52,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No matching people found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Try Any distance, clear your search, or refresh again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _maximumDistanceKm = null);
                      _applyFilters();
                    },
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            )
          else
            ..._visibleUsers.map(
              (candidate) => NearbyUserCard(
                user: candidate,
                distanceText: NearbyUserPresenter.distanceText(
                  _distanceByUserId[candidate.uid],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
