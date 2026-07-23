import 'dart:math' as math;

import '../constants/app_constants.dart';
import '../models/app_user.dart';

class NearbyUserPresenter {
  const NearbyUserPresenter._();

  static bool hasValidLocation(AppUser user) {
    final latitude = user.latitude;
    final longitude = user.longitude;
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static bool isEffectivelyOnline(AppUser user, {DateTime? now}) {
    if (!user.isOnline || user.lastSeen == null) return false;

    final referenceTime = now ?? DateTime.now();
    final difference = referenceTime.difference(user.lastSeen!);

    if (difference.isNegative) {
      return difference.inMinutes.abs() <= 1;
    }

    return difference.inMinutes <= AppConstants.presenceFreshnessMinutes;
  }

  static bool wasRecentlyActive(
    AppUser user, {
    DateTime? now,
    Duration window = const Duration(hours: 24),
  }) {
    if (isEffectivelyOnline(user, now: now)) return true;
    if (user.lastSeen == null) return false;

    final referenceTime = now ?? DateTime.now();
    final difference = referenceTime.difference(user.lastSeen!);
    return !difference.isNegative && difference <= window;
  }

  static double? distanceKm(AppUser currentUser, AppUser otherUser) {
    if (!hasValidLocation(currentUser) || !hasValidLocation(otherUser)) {
      return null;
    }

    const earthRadiusKm = 6371.0;
    final lat1 = _degreesToRadians(currentUser.latitude!);
    final lat2 = _degreesToRadians(otherUser.latitude!);
    final deltaLat = _degreesToRadians(
      otherUser.latitude! - currentUser.latitude!,
    );
    final deltaLon = _degreesToRadians(
      otherUser.longitude! - currentUser.longitude!,
    );

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static String distanceText(double? distanceKm) {
    if (distanceKm == null || distanceKm.isNaN || distanceKm.isInfinite) {
      return 'Distance unavailable';
    }

    if (distanceKm < 1) return 'Less than 1 km';
    return '${distanceKm.round()} km';
  }

  static String privacySafeLocationText({
    required String distanceText,
    String? state,
  }) {
    final safeState = state?.trim();
    if (safeState == null || safeState.isEmpty) return distanceText;
    return '$distanceText \u2022 $safeState';
  }

  static String lastSeenText(AppUser user, {DateTime? now}) {
    if (isEffectivelyOnline(user, now: now)) return 'Online now';
    if (user.lastSeen == null) return 'Offline';

    final referenceTime = now ?? DateTime.now();
    final difference = referenceTime.difference(user.lastSeen!);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Active just now';
    }
    if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return 'Active ${difference.inHours} hr ago';
    }
    if (difference.inDays == 1) return 'Active yesterday';
    if (difference.inDays < 7) {
      return 'Active ${difference.inDays} days ago';
    }

    return 'Offline';
  }

  static bool areMutuallyCompatible(AppUser currentUser, AppUser otherUser) {
    return _preferenceMatches(currentUser.lookingFor, otherUser.gender) &&
        _preferenceMatches(otherUser.lookingFor, currentUser.gender);
  }

  static List<AppUser> filterEligibleUsers({
    required AppUser currentUser,
    required Iterable<AppUser> candidates,
    double? maxDistanceKm,
  }) {
    final boundedRadius = maxDistanceKm?.clamp(
      1,
      AppConstants.maximumNearbyRadiusKm,
    );

    return candidates.where((user) {
      if (user.uid == currentUser.uid) return false;
      if (user.isSuspended || !user.isAdult) return false;
      if (!areMutuallyCompatible(currentUser, user)) return false;
      if (currentUser.blockedUsers.contains(user.uid)) return false;
      if (user.blockedUsers.contains(currentUser.uid)) return false;

      if (boundedRadius != null) {
        final distance = distanceKm(currentUser, user);
        if (distance == null || distance > boundedRadius) return false;
      }

      return true;
    }).toList();
  }

  static void sortUsers({
    required AppUser currentUser,
    required List<AppUser> users,
  }) {
    users.sort((a, b) {
      final aOnline = isEffectivelyOnline(a);
      final bOnline = isEffectivelyOnline(b);

      // Online users always come first.
      if (aOnline != bOnline) return aOnline ? -1 : 1;

      // Within each group, nearest users come first.
      final aDistance = distanceKm(currentUser, a);
      final bDistance = distanceKm(currentUser, b);
      final aHasDistance = aDistance != null;
      final bHasDistance = bDistance != null;

      if (aHasDistance != bHasDistance) return aHasDistance ? -1 : 1;
      if (aHasDistance && bHasDistance) {
        final distanceComparison = aDistance.compareTo(bDistance);
        if (distanceComparison != 0) return distanceComparison;
      }

      // For equally near users, the most recently active person comes first.
      final aSeen = a.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bSeen = b.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
      final activityComparison = bSeen.compareTo(aSeen);
      if (activityComparison != 0) return activityComparison;

      return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
    });
  }

  static bool _preferenceMatches(String preference, String gender) {
    return preference == 'Both' || preference == gender;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
