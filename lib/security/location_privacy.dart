import 'dart:math' as math;

class LocationPrivacy {
  const LocationPrivacy._();

  static const int privacyVersion = 1;
  static const int coordinatePrecision = 2;
  static const double discoveryCellSizeDegrees = 0.5;
  static const int discoveryCellRadius = 1;
  static const int maximumDiscoveryCells = 9;

  static bool isValidLatitude(double? value) {
    return value != null && value.isFinite && value >= -90 && value <= 90;
  }

  static bool isValidLongitude(double? value) {
    return value != null && value.isFinite && value >= -180 && value <= 180;
  }

  static double? approximateLatitude(double? latitude) {
    if (!isValidLatitude(latitude)) return null;
    return _round(latitude!);
  }

  static double? approximateLongitude(double? longitude) {
    if (!isValidLongitude(longitude)) return null;
    return _round(longitude!);
  }

  static String? discoveryCellFor(double? latitude, double? longitude) {
    if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) return null;

    final latIndex = _latitudeIndex(latitude!);
    final lngIndex = _longitudeIndex(longitude!);
    return '$latIndex:$lngIndex';
  }

  static List<String> neighboringDiscoveryCells(
    double? latitude,
    double? longitude,
  ) {
    if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
      return const <String>[];
    }

    final centerLat = _latitudeIndex(latitude!);
    final centerLng = _longitudeIndex(longitude!);
    final latCellCount = (180 / discoveryCellSizeDegrees).ceil();
    final lngCellCount = (360 / discoveryCellSizeDegrees).ceil();
    final cells = <String>{};

    for (
      var latOffset = -discoveryCellRadius;
      latOffset <= discoveryCellRadius;
      latOffset++
    ) {
      final latIndex = (centerLat + latOffset)
          .clamp(0, latCellCount - 1)
          .toInt();
      for (
        var lngOffset = -discoveryCellRadius;
        lngOffset <= discoveryCellRadius;
        lngOffset++
      ) {
        final lngIndex = (centerLng + lngOffset) % lngCellCount;
        cells.add('$latIndex:$lngIndex');
      }
    }

    final result = cells.toList()..sort();
    assert(result.length <= maximumDiscoveryCells);
    return result;
  }

  static double _round(double value) {
    final factor = math.pow(10, coordinatePrecision).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  static int _latitudeIndex(double latitude) {
    final cellCount = (180 / discoveryCellSizeDegrees).ceil();
    return ((latitude + 90) / discoveryCellSizeDegrees)
        .floor()
        .clamp(0, cellCount - 1)
        .toInt();
  }

  static int _longitudeIndex(double longitude) {
    final cellCount = (360 / discoveryCellSizeDegrees).ceil();
    return ((longitude + 180) / discoveryCellSizeDegrees)
        .floor()
        .clamp(0, cellCount - 1)
        .toInt();
  }
}
