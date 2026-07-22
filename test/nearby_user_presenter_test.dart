import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/app_user.dart';
import 'package:nearmeu/utils/nearby_user_presenter.dart';

AppUser user(
  String uid, {
  int age = 25,
  bool suspended = false,
  bool online = false,
  double? latitude,
  double? longitude,
  String? state,
  String gender = 'Female',
  String lookingFor = 'Male',
  List<String> blocked = const [],
}) {
  return AppUser(
    uid: uid,
    email: '$uid@example.com',
    nickname: uid,
    gender: gender,
    lookingFor: lookingFor,
    createdAt: DateTime(2024),
    age: age,
    isSuspended: suspended,
    isOnline: online,
    latitude: latitude,
    longitude: longitude,
    state: state,
    blockedUsers: blocked,
  );
}

void main() {
  final current = user(
    'me',
    gender: 'Male',
    lookingFor: 'Female',
    latitude: 23.2599,
    longitude: 77.4126,
    blocked: const ['blocked'],
  );

  test('only mutually compatible nearby adults are eligible', () {
    final result = NearbyUserPresenter.filterEligibleUsers(
      currentUser: current,
      candidates: [
        current,
        user('eligible', latitude: 23.27, longitude: 77.42),
        user('underage', age: 17, latitude: 23.27, longitude: 77.42),
        user(
          'suspended',
          suspended: true,
          latitude: 23.27,
          longitude: 77.42,
        ),
        user('blocked', latitude: 23.27, longitude: 77.42),
        user(
          'blockedMe',
          latitude: 23.27,
          longitude: 77.42,
          blocked: const ['me'],
        ),
        user(
          'oneSided',
          latitude: 23.27,
          longitude: 77.42,
          lookingFor: 'Female',
        ),
      ],
    );

    expect(result.map((candidate) => candidate.uid), ['eligible']);
  });

  test('online users and valid-distance users sort before unavailable distances', () {
    final users = [
      user('offlineNoLocation'),
      user('onlineNoLocation', online: true),
      user('offlineNear', latitude: 23.27, longitude: 77.42),
      user('onlineFar', online: true, latitude: 24.0, longitude: 78.0),
      user('onlineNear', online: true, latitude: 23.26, longitude: 77.41),
    ];

    NearbyUserPresenter.sortUsers(currentUser: current, users: users);

    expect(users.map((candidate) => candidate.uid), [
      'onlineNear',
      'onlineFar',
      'onlineNoLocation',
      'offlineNear',
      'offlineNoLocation',
    ]);
  });

  test('default discovery radius is 25 km and cannot exceed 50 km', () {
    final near = user('near', latitude: 23.35, longitude: 77.45);
    final medium = user('medium', latitude: 23.6, longitude: 77.5);
    final far = user('far', latitude: 24.0, longitude: 77.5);

    expect(
      NearbyUserPresenter.filterEligibleUsers(
        currentUser: current,
        candidates: [near, medium, far],
      ).map((candidate) => candidate.uid),
      ['near'],
    );
    expect(
      NearbyUserPresenter.filterEligibleUsers(
        currentUser: current,
        candidates: [near, medium, far],
        maxDistanceKm: 50,
      ).map((candidate) => candidate.uid),
      ['near', 'medium'],
    );
    expect(
      NearbyUserPresenter.filterEligibleUsers(
        currentUser: current,
        candidates: [far],
        maxDistanceKm: 1000,
      ),
      isEmpty,
    );
  });

  test('distance display uses whole kilometres and no exact coordinates', () {
    expect(NearbyUserPresenter.distanceText(0.2), '1 km');
    expect(NearbyUserPresenter.distanceText(2.49), '2 km');
    expect(NearbyUserPresenter.distanceText(2.5), '3 km');
    expect(NearbyUserPresenter.distanceText(100.4), '100 km');
    expect(NearbyUserPresenter.distanceText(null), 'Distance unavailable');
  });

  test('nearby cards get privacy-safe state-only location text', () {
    expect(
      NearbyUserPresenter.privacySafeLocationText(
        distanceText: '3 km',
        state: 'Madhya Pradesh',
      ),
      '3 km • Madhya Pradesh',
    );
    expect(
      NearbyUserPresenter.privacySafeLocationText(distanceText: '3 km'),
      '3 km',
    );
  });
}
