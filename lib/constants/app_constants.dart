class AppConstants {
  static const int minimumUserAge = 18;
  static const int maximumUserAge = 99;

  // Load enough candidates to show 25-30 real users when available.
  // Firestore rules intentionally cap non-admin discovery queries at 50.
  static const int nearbyPageSize = 50;
  static const int nearbyInitialTarget = 30;

  static const int maxBlockedUsers = 500;
  static const double defaultNearbyRadiusKm = 25;
  static const double maximumNearbyRadiusKm = 100;

  // Presence publishes a heartbeat while the app is active. A user is only
  // treated as online while this timestamp remains fresh.
  static const int presenceHeartbeatMinutes = 2;
  static const int presenceFreshnessMinutes = 5;
}
