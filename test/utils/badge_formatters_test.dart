import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/utils/badge_formatters.dart';

void main() {
  group('BadgeFormatters.unread', () {
    test('hides zero and negative counts', () {
      expect(BadgeFormatters.unread(0), '');
      expect(BadgeFormatters.unread(-3), '');
    });

    test('formats normal counts', () {
      expect(BadgeFormatters.unread(1), '1');
      expect(BadgeFormatters.unread(9), '9');
      expect(BadgeFormatters.unread(99), '99');
    });

    test('caps large counts at 99+', () {
      expect(BadgeFormatters.unread(100), '99+');
      expect(BadgeFormatters.unread(500), '99+');
    });
  });
}
