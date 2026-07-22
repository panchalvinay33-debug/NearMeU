import 'dart:math' as math;

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
    final deltaLat = _degreesToRadians(otherUser.latitude! - currentUser.latitude!);
    final deltaLon = _degreesToRadians(otherUser.longitude! - currentUser.longitude!);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
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

  static String privacySafeLocationText({required String distanceText, String? state}) {
    final safeState = state?.trim();
    if (safeState == null || safeState.isEmpty) {
      return distanceText;
    }
    return '$distanceText • $safeState';
  }

  static bool hasRequiredIdentityFields(AppUser user) {
    return user.uid.trim().isNotEmpty &&
        user.email.trim().isNotEmpty &&
        user.nickname.trim().isNotEmpty &&
        user.gender.trim().isNotEmpty &&
        user.lookingFor.trim().isNotEmpty;
  }

  static List<AppUser> filterEligibleUsers({
    required AppUser currentUser,
    required Iterable<AppUser> candidates,
    double? maxDistanceKm,
    bool onlineOnly = false,
    String? gender,
    String? lookingFor,
    int minAge = 18,
    int maxAge = 99,
  }) {
    return candidates.where((user) {
      if (user.uid == currentUser.uid) return false;
      if (user.isSuspended || !user.isAdult) return false;
      if (!hasRequiredIdentityFields(user)) return false;
      if (currentUser.blockedUsers.contains(user.uid)) return false;
      if (user.blockedUsers.contains(currentUser.uid)) return false;
      if (onlineOnly && !user.isOnline) return false;
      final userAge = user.age;
      if (userAge == null || userAge < minAge || userAge > maxAge) return false;
      if (gender != null && gender.toLowerCase() != 'all' && user.gender.toLowerCase() != gender.toLowerCase()) {
        return false;
      }
      if (lookingFor != null && lookingFor.toLowerCase() != 'all' && user.lookingFor.toLowerCase() != lookingFor.toLowerCase()) {
        return false;
      }
      if (maxDistanceKm != null) {
        final distance = distanceKm(currentUser, user);
        if (distance == null || distance > maxDistanceKm) return false;
      }
      return true;
    }).toList();
  }

  static void sortNearestFirst({required AppUser currentUser, required List<AppUser> users}) {
    users.sort((a, b) {
      final aDistance = distanceKm(currentUser, a);
      final bDistance = distanceKm(currentUser, b);
      final aHasDistance = aDistance != null;
      final bHasDistance = bDistance != null;
      if (aHasDistance != bHasDistance) return aHasDistance ? -1 : 1;
      if (aHasDistance && bHasDistance) return aDistance.compareTo(bDistance);
      return sortRecentlyActive(a, b);
    });
  }

  static int sortRecentlyActive(AppUser a, AppUser b) {
    final aSeen = a.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bSeen = b.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bSeen.compareTo(aSeen);
  }

  static void sortUsers({required AppUser currentUser, required List<AppUser> users}) {
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

      return sortRecentlyActive(a, b);
    });
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
