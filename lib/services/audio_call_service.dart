import 'package:cloud_functions/cloud_functions.dart';

class AudioCallSession {
  const AudioCallSession({
    required this.callId,
    required this.role,
    required this.status,
    required this.otherUserId,
    required this.otherUserName,
    this.appId,
    this.channelName,
    this.token,
    this.agoraUid,
    this.createdAtMillis,
    this.acceptedAtMillis,
    this.endedAtMillis,
    this.ringExpiresAtMillis,
    this.expiresAtMillis,
    this.tokenExpiresAtMillis,
  });

  final String callId;
  final String role;
  final String status;
  final String otherUserId;
  final String otherUserName;
  final String? appId;
  final String? channelName;
  final String? token;
  final int? agoraUid;
  final int? createdAtMillis;
  final int? acceptedAtMillis;
  final int? endedAtMillis;
  final int? ringExpiresAtMillis;
  final int? expiresAtMillis;
  final int? tokenExpiresAtMillis;

  bool get isCaller => role == 'caller';
  bool get isCallee => role == 'callee';
  bool get isRinging => status == 'ringing';
  bool get isAccepted => status == 'accepted';
  bool get isTerminal =>
      status == 'declined' ||
      status == 'ended' ||
      status == 'missed' ||
      status == 'expired';
  bool get hasRtcAccess =>
      appId?.isNotEmpty == true &&
      channelName?.isNotEmpty == true &&
      token?.isNotEmpty == true &&
      agoraUid != null;

  factory AudioCallSession.fromMap(Map<dynamic, dynamic> data) {
    int? intValue(String key) {
      final value = data[key];
      return value is num ? value.toInt() : null;
    }

    return AudioCallSession(
      callId: data['callId']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      otherUserId: data['otherUserId']?.toString() ?? '',
      otherUserName: data['otherUserName']?.toString().trim().isNotEmpty == true
          ? data['otherUserName'].toString().trim()
          : 'NearMeU user',
      appId: data['appId']?.toString(),
      channelName: data['channelName']?.toString(),
      token: data['token']?.toString(),
      agoraUid: intValue('agoraUid'),
      createdAtMillis: intValue('createdAtMillis'),
      acceptedAtMillis: intValue('acceptedAtMillis'),
      endedAtMillis: intValue('endedAtMillis'),
      ringExpiresAtMillis: intValue('ringExpiresAtMillis'),
      expiresAtMillis: intValue('expiresAtMillis'),
      tokenExpiresAtMillis: intValue('tokenExpiresAtMillis'),
    );
  }
}

class AudioCallException implements Exception {
  const AudioCallException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AudioCallService {
  AudioCallService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<AudioCallSession> startCall(String calleeUid) async {
    return _sessionCall(
      'startAudioCall',
      <String, dynamic>{'calleeUid': calleeUid},
    );
  }

  Future<AudioCallSession> getCall(String callId) async {
    return _sessionCall(
      'getAudioCall',
      <String, dynamic>{'callId': callId},
    );
  }

  Future<AudioCallSession> respond({
    required String callId,
    required bool accept,
  }) async {
    return _sessionCall(
      'respondAudioCall',
      <String, dynamic>{'callId': callId, 'accept': accept},
    );
  }

  Future<void> endCall(String callId) async {
    try {
      await _functions.httpsCallable('endAudioCall').call<void>(
        <String, dynamic>{'callId': callId},
      );
    } on FirebaseFunctionsException catch (error) {
      throw _mapException(error);
    }
  }

  Future<AudioCallSession> _sessionCall(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<dynamic>(data);
      final payload = result.data;
      if (payload is! Map) {
        throw const AudioCallException('Audio call response was invalid.');
      }
      final session = AudioCallSession.fromMap(payload);
      if (session.callId.isEmpty || session.status.isEmpty) {
        throw const AudioCallException('Audio call response was incomplete.');
      }
      return session;
    } on FirebaseFunctionsException catch (error) {
      throw _mapException(error);
    }
  }

  AudioCallException _mapException(FirebaseFunctionsException error) {
    final details = error.details;
    final reason = details is Map ? details['reason']?.toString() : null;
    final raw = error.message?.trim();
    if (reason == 'premium-required') {
      return const AudioCallException(
        'Premium is required to start an audio call.',
        code: 'premium-required',
      );
    }
    if (reason == 'agora-not-configured') {
      return const AudioCallException(
        'Audio calling is being configured. Please try again later.',
        code: 'agora-not-configured',
      );
    }
    return AudioCallException(
      raw == null || raw.isEmpty ? 'Audio call could not be completed.' : raw,
      code: error.code,
    );
  }
}
