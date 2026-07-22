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
  bool _onlineOnly = false;
  String _gender = 'All';
  String _lookingFor = 'All';
  RangeValues _ageRange = const RangeValues(18, 99);
  String _sort = 'Recommended';

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
          onlineOnly: _onlineOnly,
          gender: _gender,
          lookingFor: _lookingFor,
          minAge: _ageRange.start.round(),
          maxAge: _ageRange.end.round(),
        );
        result
          ..clear()
          ..addAll(filtered);
        await _cacheDistances(result);
        _sortUsers(result);
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
            onlineOnly: _onlineOnly,
            gender: _gender,
            lookingFor: _lookingFor,
            minAge: _ageRange.start.round(),
            maxAge: _ageRange.end.round(),
          );
          result
            ..clear()
            ..addAll(filtered);
          await _cacheDistances(result);
          _sortUsers(result);
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

  void _sortUsers(List<AppUser> result) {
    if (currentMe == null) return;
    switch (_sort) {
      case 'Nearest first':
        NearbyUserPresenter.sortNearestFirst(currentUser: currentMe!, users: result);
        break;
      case 'Recently active':
        result.sort(NearbyUserPresenter.sortRecentlyActive);
        break;
      default:
        NearbyUserPresenter.sortUsers(currentUser: currentMe!, users: result);
    }
  }

  bool get _hasActiveFilters =>
      _onlineOnly ||
      _appliedMaxDistanceKm != null ||
      _gender != 'All' ||
      _lookingFor != 'All' ||
      _ageRange.start.round() != 18 ||
      _ageRange.end.round() != 99 ||
      _sort != 'Recommended';

  Future<void> _clearAllFilters() async {
    setState(() {
      _onlineOnly = false;
      _appliedMaxDistanceKm = null;
      _gender = 'All';
      _lookingFor = 'All';
      _ageRange = const RangeValues(18, 99);
      _sort = 'Recommended';
    });
    await _loadNearbyUsers(showLoader: false);
  }

  Future<void> _openFilterSheet() async {
    var onlineOnly = _onlineOnly;
    var distance = _appliedMaxDistanceKm;
    var gender = _gender;
    var lookingFor = _lookingFor;
    var ageRange = _ageRange;
    var sort = _sort;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const Expanded(child: Text('Nearby filters', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                  IconButton(tooltip: 'Close filters', onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close, color: Colors.white70)),
                ]),
                SwitchListTile.adaptive(title: const Text('Online only', style: TextStyle(color: Colors.white)), value: onlineOnly, activeColor: AppColors.primary, onChanged: (v) => setSheetState(() => onlineOnly = v)),
                _FilterDropdown<double?>(label: 'Distance', value: distance, items: const {null: 'Any distance', 25.0: 'Within 25 km', 50.0: 'Within 50 km', 100.0: 'Within 100 km'}, onChanged: (v) => setSheetState(() => distance = v)),
                _FilterDropdown<String>(label: 'Gender', value: gender, items: const {'All': 'All', 'Male': 'Male', 'Female': 'Female', 'Other': 'Other'}, onChanged: (v) => setSheetState(() => gender = v ?? 'All')),
                _FilterDropdown<String>(label: 'Looking For', value: lookingFor, items: const {'All': 'All', 'Male': 'Male', 'Female': 'Female', 'Both': 'Both'}, onChanged: (v) => setSheetState(() => lookingFor = v ?? 'All')),
                const SizedBox(height: 12),
                Text('Age range ${ageRange.start.round()}–${ageRange.end.round()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                RangeSlider(values: ageRange, min: 18, max: 99, divisions: 81, activeColor: AppColors.primary, labels: RangeLabels('${ageRange.start.round()}', '${ageRange.end.round()}'), onChanged: (v) => setSheetState(() => ageRange = v)),
                _FilterDropdown<String>(label: 'Sort', value: sort, items: const {'Recommended': 'Recommended', 'Nearest first': 'Nearest first', 'Recently active': 'Recently active'}, onChanged: (v) => setSheetState(() => sort = v ?? 'Recommended')),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () { setSheetState(() { onlineOnly = false; distance = null; gender = 'All'; lookingFor = 'All'; ageRange = const RangeValues(18, 99); sort = 'Recommended'; }); }, child: const Text('Clear All'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply'))),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
    if (applied != true) return;
    setState(() { _onlineOnly = onlineOnly; _appliedMaxDistanceKm = distance; _gender = gender; _lookingFor = lookingFor; _ageRange = ageRange; _sort = sort; });
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

  if (_hasActiveFilters) ...[
    const SizedBox(height: 14),
    Wrap(spacing: 8, runSpacing: 8, children: [
      if (_onlineOnly) const Chip(label: Text('Online only')),
      if (_appliedMaxDistanceKm != null) Chip(label: Text('Within ${_appliedMaxDistanceKm!.round()} km')),
      if (_gender != 'All') Chip(label: Text('Gender: $_gender')),
      if (_lookingFor != 'All') Chip(label: Text('Looking for: $_lookingFor')),
      if (_ageRange.start.round() != 18 || _ageRange.end.round() != 99) Chip(label: Text('Ages ${_ageRange.start.round()}–${_ageRange.end.round()}')),
      if (_sort != 'Recommended') Chip(label: Text(_sort)),
      ActionChip(label: const Text('Clear All'), onPressed: _clearAllFilters),
    ]),
  ],

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
            tooltip: 'Open filters',
            onPressed: _openFilterSheet,
            icon: Icon(_hasActiveFilters ? Icons.filter_alt : Icons.tune),
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
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
        ),
        style: const TextStyle(color: Colors.white),
        items: items.entries.map((entry) => DropdownMenuItem<T>(value: entry.key, child: Text(entry.value))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
