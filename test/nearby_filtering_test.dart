import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/app_user.dart';
import 'package:nearmeu/utils/nearby_filtering.dart';

AppUser user(String id, {bool online = false, double? km, String gender = 'Male', String lookingFor = 'Female', int age = 25, DateTime? seen}) => AppUser(uid: id, email: '$id@test.com', nickname: id, gender: gender, lookingFor: lookingFor, createdAt: DateTime(2026), age: age, isOnline: online, lastSeen: seen);

void main() {
  test('Nearby sorting places online users first, then distance', () {
    final sorted = filterAndSortNearbyUsers(users: [
      NearbyUserViewData(user: user('offline-near'), distanceKm: 1),
      NearbyUserViewData(user: user('online-far', online: true), distanceKm: 9),
      NearbyUserViewData(user: user('online-near', online: true), distanceKm: 2),
      NearbyUserViewData(user: user('offline-far'), distanceKm: 5),
    ], filters: const NearbyFilters());

    expect(sorted.map((e) => e.user.uid), ['online-near', 'online-far', 'offline-near', 'offline-far']);
  });

  test('Nearby filters constrain online, distance, gender, looking for, and age', () {
    final sorted = filterAndSortNearbyUsers(users: [
      NearbyUserViewData(user: user('match', online: true, gender: 'Female', lookingFor: 'Both', age: 30), distanceKm: 12),
      NearbyUserViewData(user: user('offline', gender: 'Female', lookingFor: 'Both', age: 30), distanceKm: 12),
      NearbyUserViewData(user: user('far', online: true, gender: 'Female', lookingFor: 'Both', age: 30), distanceKm: 80),
      NearbyUserViewData(user: user('young', online: true, gender: 'Female', lookingFor: 'Both', age: 18), distanceKm: 12),
    ], filters: const NearbyFilters(onlineOnly: true, minDistanceKm: 0, maxDistanceKm: 20, gender: NearbyGenderFilter.female, lookingFor: NearbyLookingForFilter.both, minAge: 25, maxAge: 35));

    expect(sorted.map((e) => e.user.uid), ['match']);
  });
}
