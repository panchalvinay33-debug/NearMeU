import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/audio_call_model.dart';

class AudioCallService {
  AudioCallService({FirebaseFunctions? functions, FirebaseAuth? auth})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<AudioCallSessionPayload> startCall(String calleeId) async {
    final result = await _authenticatedCall<Map<String, dynamic>>(
      'startAudioCall',
      <String, dynamic>{'calleeId': calleeId},
    );
    return _payload(result.data);
  }

  Future<AudioCallSessionPayload> respond({
    required String callId,
    required bool accept,
  }) async {
    final result = await _authenticatedCall<Map<String, dynamic>>(
      'respondAudioCall',
      <String, dynamic>{'callId': callId, 'accept': accept},
    );
    return _payload(result.data);
  }

  Future<AudioCallSessionPayload> getCall(String callId) async {
    final result = await _authenticatedCall<Map<String, dynamic>>(
      'getAudioCall',
      <String, dynamic>{'callId': callId},
    );
    return _payload(result.data);
  }

  Future<AudioCallSessionPayload?> getPendingCall() async {
    final result = await _authenticatedCall<Map<String, dynamic>>('getPendingAudioCall');
    final call = result.data['call'];
    if (call is! Map) return null;
    return _payload(result.data);
  }

  Future<AudioCallModel> endCall(String callId, {String reason = 'ended'}) async {
    final result = await _authenticatedCall<Map<String, dynamic>>(
      'endAudioCall',
      <String, dynamic>{'callId': callId, 'reason': reason},
    );
    final call = result.data['call'];
    if (call is! Map) throw const AudioCallException('Call state was not returned.');
    return AudioCallModel.fromMap(Map<String, dynamic>.from(call));
  }

  Future<List<AudioCallModel>> history() async {
    final result = await _authenticatedCall<Map<String, dynamic>>('listAudioCallHistory');
    final raw = result.data['calls'];
    if (raw is! List) return const <AudioCallModel>[];
    return raw
        .whereType<Map>()
        .map((item) => AudioCallModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<HttpsCallableResult<T>> _authenticatedCall<T>(
    String functionName, [
    Object? data,
  ]) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AudioCallException('Please sign in again before making a call.');
    }

    await user.getIdToken();
    final callable = _functions.httpsCallable(functionName);
    try {
      return await callable.call<T>(data);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'unauthenticated') rethrow;

      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        throw const AudioCallException('Please sign in again before making a call.');
      }
      await refreshedUser.getIdToken(true);
      return callable.call<T>(data);
    }
  }

  AudioCallSessionPayload _payload(Map<String, dynamic> data) {
    final call = data['call'];
    if (call is! Map) throw const AudioCallException('Call state was not returned.');
    final rtc = data['rtc'];
    return AudioCallSessionPayload(
      call: AudioCallModel.fromMap(Map<String, dynamic>.from(call)),
      rtc: rtc is Map
          ? AgoraRtcCredentials.fromMap(Map<String, dynamic>.from(rtc))
          : null,
    );
  }
}

class AudioCallException implements Exception {
  const AudioCallException(this.message);
  final String message;
  @override
  String toString() => message;
}
