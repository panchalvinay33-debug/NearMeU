import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Chats screen does not contain Your Chats summary block', () {
    final source = read('lib/screens/chats_screen.dart');
    expect(source, isNot(contains('Your Chats')));
    expect(source, isNot(contains('active conversation')));
  });

  test('Settings contains the grouped section headings', () {
    final source = read('lib/screens/settings_screen.dart');
    for (final heading in [
      'Account',
      'Privacy & Safety',
      'Notifications',
      'Admin',
      'Support & Legal',
      'Account Actions',
    ]) {
      expect(source, contains("_settingsSection('$heading'"));
    }
  });

  test('Nearby filter icon opens the full filter bottom sheet', () {
    final source = read('lib/screens/nearby_screen.dart');
    expect(source, contains("tooltip: 'Open filters'"));
    expect(source, contains('showModalBottomSheet<bool>'));
    for (final option in [
      'Online only',
      'Any distance',
      'Within 25 km',
      'Within 50 km',
      'Within 100 km',
      'Gender',
      'Looking For',
      'Age range',
      'Recommended',
      'Nearest first',
      'Recently active',
      'Clear All',
      'Apply',
    ]) {
      expect(source, contains(option));
    }
    expect(source, isNot(contains('PopupMenuButton<double?>')));
  });

  test('Announcement screen continues to load active announcements', () {
    final screen = read('lib/screens/support_announcements_screen.dart');
    final service = read('lib/services/announcement_service.dart');
    expect(screen, contains('watchActiveAnnouncements'));
    expect(service, contains('supportAnnouncements'));
    expect(service, contains('isActive'));
  });
}
