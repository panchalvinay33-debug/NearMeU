import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/utils/distance_formatters.dart';

void main() {
  group('whole kilometer distance formatting', () {
    test('rounds positive distances without metres or decimals', () {
      expect(DistanceFormatters.wholeKilometers(0.1), '1 km');
      expect(DistanceFormatters.wholeKilometers(0.8), '1 km');
      expect(DistanceFormatters.wholeKilometers(1.4), '1 km');
      expect(DistanceFormatters.wholeKilometers(1.6), '2 km');
      expect(DistanceFormatters.wholeKilometers(110.2), '110 km');
    });

    test('shows unavailable text for missing or invalid distances', () {
      expect(DistanceFormatters.wholeKilometers(null), 'Distance unavailable');
      expect(DistanceFormatters.wholeKilometers(0), 'Distance unavailable');
      expect(DistanceFormatters.wholeKilometers(-0.1), 'Distance unavailable');
      expect(
        DistanceFormatters.wholeKilometers(double.nan),
        'Distance unavailable',
      );
      expect(
        DistanceFormatters.wholeKilometers(double.infinity),
        'Distance unavailable',
      );
    });
  });
}
