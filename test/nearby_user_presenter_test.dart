import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/app_user.dart';
import 'package:nearmeu/utils/nearby_user_presenter.dart';

AppUser user(
  String uid, {
  int? age = 25,
  String gender = 'Female',
  String lookingFor = 'Male',
  bool suspended = false,
  bool online = false,
  double? latitude,
  double? longitude,
  String? state,
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
    blocked: ['blocked'],
  );

  test('all eligible compatible users are included', () {
    final result = NearbyUserPresenter.filterEligibleUsers(
      currentUser: current,
      candidates: [
        current,
        user('eligible'),
        user('underage', age: 17),
        user('missingAge', age: null),
        user('suspended', suspended: true),
        user('blocked'),
        user('blockedMe', blocked: ['me']),
        user(
          'notInterested',
          gender: 'Female',
          lookingFor: 'Female',
        ),
      ],
    );

    expect(result.map((u) => u.uid), ['eligible']);
  });

  test('compatibility accepts legacy Men and Women labels', () {
    final legacyMale = user(
      'legacyMale',
      gender: 'Man',
      lookingFor: 'Women',
    );
    final legacyFemale = user(
      'legacyFemale',
      gender: 'Woman',
      lookingFor: 'Men',
    );

    expect(
      NearbyUserPresenter.areMutuallyCompatible(legacyMale, legacyFemale),
      isTrue,
    );
  });

  test('compatibility must be mutual', () {
    final maleLookingForFemale = user(
      'male',
      gender: 'Male',
      lookingFor: 'Female',
    );
    final femaleLookingForFemale = user(
      'female',
      gender: 'Female',
      lookingFor: 'Female',
    );

    expect(
      NearbyUserPresenter.areMutuallyCompatible(
        maleLookingForFemale,
        femaleLookingForFemale,
      ),
      isFalse,
    );
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

    expect(users.map((u) => u.uid), [
      'onlineNear',
      'onlineFar',
      'onlineNoLocation',
      'offlineNear',
      'offlineNoLocation',
    ]);
  });

  test('default filters keep distant compatible users', () {
    final far = user('far', latitude: 28.6139, longitude: 77.2090);
    expect(
      NearbyUserPresenter.filterEligibleUsers(
        currentUser: current,
        candidates: [far],
      ).map((u) => u.uid),
      ['far'],
    );
    expect(
      NearbyUserPresenter.filterEligibleUsers(
        currentUser: current,
        candidates: [far],
        maxDistanceKm: 100,
      ),
      isEmpty,
    );
  });

  test('distance display uses whole kilometres', () {
    expect(NearbyUserPresenter.distanceText(0.2), '1 km');
    expect(NearbyUserPresenter.distanceText(2.49), '2 km');
    expect(NearbyUserPresenter.distanceText(2.5), '3 km');
    expect(NearbyUserPresenter.distanceText(100.4), '100 km');
    expect(NearbyUserPresenter.distanceText(109.6), '110 km');
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
