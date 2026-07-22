class DistanceFormatters {
  const DistanceFormatters._();

  static const String unavailable = 'Distance unavailable';

  static String wholeKilometers(double? distanceKm) {
    if (distanceKm == null || !distanceKm.isFinite || distanceKm <= 0) {
      return unavailable;
    }

    final roundedKm = distanceKm < 1 ? 1 : distanceKm.round();
    return '$roundedKm km';
  }
}
