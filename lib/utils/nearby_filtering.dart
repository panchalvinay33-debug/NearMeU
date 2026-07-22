import '../constants/app_constants.dart';
import '../models/app_user.dart';

enum NearbyGenderFilter { all, male, female, other }
enum NearbyLookingForFilter { all, male, female, both }
enum NearbySortMode { recommended, nearestFirst, recentlyActive }

class NearbyFilters {
  const NearbyFilters({
    this.onlineOnly = false,
    this.minDistanceKm = 0,
    this.maxDistanceKm = 100,
    this.gender = NearbyGenderFilter.all,
    this.lookingFor = NearbyLookingForFilter.all,
    this.minAge = AppConstants.minimumUserAge,
    this.maxAge = 99,
    this.sort = NearbySortMode.recommended,
  });

  final bool onlineOnly;
  final double minDistanceKm;
  final double maxDistanceKm;
  final NearbyGenderFilter gender;
  final NearbyLookingForFilter lookingFor;
  final int minAge;
  final int maxAge;
  final NearbySortMode sort;

  bool get isDefault =>
      !onlineOnly &&
      minDistanceKm == 0 &&
      maxDistanceKm == 100 &&
      gender == NearbyGenderFilter.all &&
      lookingFor == NearbyLookingForFilter.all &&
      minAge == AppConstants.minimumUserAge &&
      maxAge == 99 &&
      sort == NearbySortMode.recommended;

  NearbyFilters copyWith({
    bool? onlineOnly,
    double? minDistanceKm,
    double? maxDistanceKm,
    NearbyGenderFilter? gender,
    NearbyLookingForFilter? lookingFor,
    int? minAge,
    int? maxAge,
    NearbySortMode? sort,
  }) =>
      NearbyFilters(
        onlineOnly: onlineOnly ?? this.onlineOnly,
        minDistanceKm: minDistanceKm ?? this.minDistanceKm,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        gender: gender ?? this.gender,
        lookingFor: lookingFor ?? this.lookingFor,
        minAge: minAge ?? this.minAge,
        maxAge: maxAge ?? this.maxAge,
        sort: sort ?? this.sort,
      );
}

class NearbyUserViewData {
  const NearbyUserViewData({required this.user, required this.distanceKm});
  final AppUser user;
  final double? distanceKm;
}

List<NearbyUserViewData> filterAndSortNearbyUsers({
  required Iterable<NearbyUserViewData> users,
  required NearbyFilters filters,
}) {
  final filtered = users.where((item) {
    final user = item.user;
    if (user.isSuspended || !user.isAdult || user.nickname.trim().isEmpty) return false;
    if (filters.onlineOnly && !user.isOnline) return false;
    final age = user.age ?? 0;
    if (age < filters.minAge || age > filters.maxAge) return false;
    if (!_matchesGender(user.gender, filters.gender)) return false;
    if (!_matchesLookingFor(user.lookingFor, filters.lookingFor)) return false;
    final distance = item.distanceKm;
    if (distance != null &&
        (distance < filters.minDistanceKm || distance > filters.maxDistanceKm)) {
      return false;
    }
    return true;
  }).toList();

  filtered.sort((a, b) {
    if (filters.sort == NearbySortMode.recentlyActive) {
      final recent = _compareRecent(a.user, b.user);
      if (recent != 0) return recent;
    }
    if (filters.sort == NearbySortMode.recommended) {
      if (a.user.isOnline != b.user.isOnline) return a.user.isOnline ? -1 : 1;
    }
    final distance = _compareDistance(a.distanceKm, b.distanceKm);
    if (distance != 0) return distance;
    return _compareRecent(a.user, b.user);
  });
  return filtered;
}

int _compareDistance(double? a, double? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _compareRecent(AppUser a, AppUser b) {
  final aSeen = a.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bSeen = b.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
  return bSeen.compareTo(aSeen);
}

bool _matchesGender(String value, NearbyGenderFilter filter) => switch (filter) {
      NearbyGenderFilter.all => true,
      NearbyGenderFilter.male => value == 'Male',
      NearbyGenderFilter.female => value == 'Female',
      NearbyGenderFilter.other => value == 'Other',
    };

bool _matchesLookingFor(String value, NearbyLookingForFilter filter) => switch (filter) {
      NearbyLookingForFilter.all => true,
      NearbyLookingForFilter.male => value == 'Male',
      NearbyLookingForFilter.female => value == 'Female',
      NearbyLookingForFilter.both => value == 'Both',
    };
