import 'package:cloud_functions/cloud_functions.dart';

import '../models/audio_call_model.dart';

class AudioCallService {
  AudioCallService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<AudioCallSessionPayload> startCall(String calleeId) async {
    final result = await _functions.httpsCallable('startAudioCall').call<Map<String, dynamic>>(
      <String, dynamic>{'calleeId': calleeId},
    );
    return _payload(result.data);
  }

  Future<AudioCallSessionPayload> respond({
    required String callId,
    required bool accept,
  }) async {
    final result = await _functions.httpsCallable('respondAudioCall').call<Map<String, dynamic>>(
      <String, dynamic>{'callId': callId, 'accept': accept},
    );
    return _payload(result.data);
  }

  Future<AudioCallSessionPayload> getCall(String callId) async {
    final result = await _functions.httpsCallable('getAudioCall').call<Map<String, dynamic>>(
      <String, dynamic>{'callId': callId},
    );
    return _payload(result.data);
  }

  Future<AudioCallSessionPayload?> getPendingCall() async {
    final result = await _functions.httpsCallable('getPendingAudioCall').call<Map<String, dynamic>>();
    final call = result.data['call'];
    if (call is! Map) return null;
    return _payload(result.data);
  }

  Future<AudioCallModel> endCall(String callId, {String reason = 'ended'}) async {
    final result = await _functions.httpsCallable('endAudioCall').call<Map<String, dynamic>>(
      <String, dynamic>{'callId': callId, 'reason': reason},
    );
    final call = result.data['call'];
    if (call is! Map) throw const AudioCallException('Call state was not returned.');
    return AudioCallModel.fromMap(Map<String, dynamic>.from(call));
  }

  Future<List<AudioCallModel>> history() async {
    final result = await _functions.httpsCallable('listAudioCallHistory').call<Map<String, dynamic>>();
    final raw = result.data['calls'];
    if (raw is! List) return const <AudioCallModel>[];
    return raw
        .whereType<Map>()
        .map((item) => AudioCallModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
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
