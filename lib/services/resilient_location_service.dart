import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'profile_schema_repair_service.dart';
import 'user_service.dart';

class ResilientLocationService {
  ResilientLocationService({
    UserService? userService,
    ProfileSchemaRepairService? profileRepair,
  }) : _userService = userService ?? UserService(),
       _profileRepair = profileRepair ?? ProfileSchemaRepairService();

  final UserService _userService;
  final ProfileSchemaRepairService _profileRepair;

  static const Duration _serviceCheckTimeout = Duration(seconds: 3);
  static const Duration _permissionTimeout = Duration(seconds: 8);
  static const Duration _lastKnownTimeout = Duration(seconds: 2);
  static const Duration _currentPositionTimeout = Duration(seconds: 9);
  static const Duration _geocodingTimeout = Duration(seconds: 4);
  static const Duration _writeTimeout = Duration(seconds: 8);

  Future<bool> refreshUserLocation(String uid) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        _serviceCheckTimeout,
      );
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission().timeout(
        _permissionTimeout,
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          _permissionTimeout,
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition().timeout(
          _lastKnownTimeout,
        );
      } catch (error, stackTrace) {
        developer.log(
          'Last-known location unavailable',
          error: error,
          stackTrace: stackTrace,
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        ).timeout(_currentPositionTimeout);
      } catch (error, stackTrace) {
        developer.log(
          'Fresh location unavailable; trying last-known location',
          error: error,
          stackTrace: stackTrace,
        );
        position = lastKnown;
      }

      if (position == null) return false;

      String? city;
      String? state;
      String? country;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(_geocodingTimeout);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality?.trim().isNotEmpty == true
              ? place.locality!.trim()
              : (place.subAdministrativeArea?.trim().isNotEmpty == true
                    ? place.subAdministrativeArea!.trim()
                    : null);
          state = place.administrativeArea;
          country = place.country;
        }
      } catch (error, stackTrace) {
        developer.log(
          'Reverse geocoding unavailable; saving coordinates without labels',
          error: error,
          stackTrace: stackTrace,
        );
      }

      Future<void> writeLocation() {
        return _userService
            .updateLocation(
              uid: uid,
              latitude: position!.latitude,
              longitude: position.longitude,
              city: city,
              state: state,
              country: country,
            )
            .timeout(_writeTimeout);
      }

      try {
        await writeLocation();
      } on FirebaseException catch (error, stackTrace) {
        if (error.code != 'permission-denied') rethrow;
        developer.log(
          'Location write rejected; attempting safe profile self-repair',
          error: error,
          stackTrace: stackTrace,
        );
        final repaired = await _profileRepair.repairCurrentProfile();
        if (!repaired) return false;
        await writeLocation();
      }
      return true;
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Location refresh timed out safely',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Location refresh failed safely',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
