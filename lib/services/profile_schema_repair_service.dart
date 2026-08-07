import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';

class ProfileSchemaRepairService {
  ProfileSchemaRepairService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  static const Duration _timeout = Duration(seconds: 8);

  Future<bool> repairCurrentProfile() async {
    try {
      final result = await _functions
          .httpsCallable('repairMyPublicProfile')
          .call<Map<String, dynamic>>()
          .timeout(_timeout);
      return result.data['repaired'] == true;
    } catch (error, stackTrace) {
      developer.log(
        'Public profile self-repair unavailable',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
