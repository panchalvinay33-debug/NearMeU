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

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
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
    final roundedKm = math.max(1, distanceKm.round());
    return '$roundedKm km';
  }

  static String privacySafeLocationText({
    required String distanceText,
    String? state,
  }) {
    final safeState = state?.trim();
    if (safeState == null || safeState.isEmpty) return distanceText;
    return '$distanceText • $safeState';
  }

  static bool areMutuallyCompatible(AppUser currentUser, AppUser otherUser) {
    return _preferenceMatches(currentUser.lookingFor, otherUser.gender) &&
        _preferenceMatches(otherUser.lookingFor, currentUser.gender);
  }

  static List<AppUser> filterEligibleUsers({
    required AppUser currentUser,
    required Iterable<AppUser> candidates,
    double maxDistanceKm = AppConstants.defaultNearbyRadiusKm,
  }) {
    final boundedRadius = maxDistanceKm.clamp(
      1,
      AppConstants.maximumNearbyRadiusKm,
    );
    return candidates.where((user) {
      if (user.uid == currentUser.uid) return false;
      if (user.isSuspended || !user.isAdult) return false;
      if (!areMutuallyCompatible(currentUser, user)) return false;
      if (currentUser.blockedUsers.contains(user.uid)) return false;
      if (user.blockedUsers.contains(currentUser.uid)) return false;
      final distance = distanceKm(currentUser, user);
      if (distance == null || distance > boundedRadius) return false;
      return true;
    }).toList();
  }

  static void sortUsers({
    required AppUser currentUser,
    required List<AppUser> users,
  }) {
    users.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;

      final aDistance = distanceKm(currentUser, a);
      final bDistance = distanceKm(currentUser, b);
      final aHasDistance = aDistance != null;
      final bHasDistance = bDistance != null;
      if (aHasDistance != bHasDistance) return aHasDistance ? -1 : 1;
      if (aHasDistance && bHasDistance) {
        final compared = aDistance.compareTo(bDistance);
        if (compared != 0) return compared;
      }

      final aSeen = a.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bSeen = b.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bSeen.compareTo(aSeen);
    });
  }

  static bool _preferenceMatches(String preference, String gender) {
    return preference == 'Both' || preference == gender;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
