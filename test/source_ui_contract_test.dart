import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chats screen renders without Your Chats summary block', () {
    final source = File('lib/screens/chats_screen.dart').readAsStringSync();
    expect(source, isNot(contains('Your Chats')));
    expect(source, contains('Recent Chats'));
    expect(source, contains('NearMeU Support'));
  });

  test('Settings screen defines premium sections', () {
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();
    for (final section in ['Account', 'Privacy & Safety', 'Notifications', 'Support & Legal', 'Admin', 'Danger Zone']) {
      expect(source, contains(section));
    }
  });
}
