import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/app_user.dart';
import 'package:nearmeu/security/location_privacy.dart';

void main() {
  test('public profile excludes private account and exact location fields', () {
    final user = AppUser(
      uid: 'alice',
      email: 'alice@example.com',
      nickname: 'Alice',
      gender: 'Female',
      lookingFor: 'Male',
      createdAt: DateTime(2026),
      latitude: 23.259912,
      longitude: 77.412612,
      city: 'Bhopal',
      state: 'Madhya Pradesh',
      country: 'India',
      blockedUsers: const ['bob'],
      messageNotificationsEnabled: false,
      nearbyAlertsEnabled: true,
    );

    final publicData = user.toPublicMap();
    final privateData = user.toPrivateMap();

    expect(publicData['approxLatitude'], 23.26);
    expect(publicData['approxLongitude'], 77.41);
    expect(publicData['locationCell'], isNotEmpty);
    expect(publicData['discoveryCells'], hasLength(9));
    expect(publicData.containsKey('email'), isFalse);
    expect(publicData.containsKey('exactLatitude'), isFalse);
    expect(publicData.containsKey('latitude'), isFalse);
    expect(publicData.containsKey('longitude'), isFalse);
    expect(publicData.containsKey('city'), isFalse);
    expect(publicData.containsKey('blockedUsers'), isFalse);
    expect(publicData.containsKey('messageNotificationsEnabled'), isFalse);
    expect(publicData.containsKey('nearbyAlertsEnabled'), isFalse);

    expect(privateData['email'], 'alice@example.com');
    expect(privateData['exactLatitude'], 23.259912);
    expect(privateData['exactLongitude'], 77.412612);
    expect(privateData['city'], 'Bhopal');
  });

  test('neighboring discovery cells are bounded and include the home cell', () {
    final home = LocationPrivacy.discoveryCellFor(23.2599, 77.4126);
    final cells = LocationPrivacy.neighboringDiscoveryCells(23.2599, 77.4126);

    expect(cells, hasLength(9));
    expect(cells, contains(home));
    expect(cells.toSet(), hasLength(cells.length));
  });

  test('invalid coordinates do not create discovery data', () {
    expect(LocationPrivacy.approximateLatitude(91), isNull);
    expect(LocationPrivacy.approximateLongitude(-181), isNull);
    expect(LocationPrivacy.discoveryCellFor(null, 77), isNull);
    expect(LocationPrivacy.neighboringDiscoveryCells(23, null), isEmpty);
  });
}
