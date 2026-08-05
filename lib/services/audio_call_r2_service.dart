import 'package:cloud_functions/cloud_functions.dart';

class AudioCallR2Session {
  const AudioCallR2Session({
    required this.callId,
    required this.role,
    required this.status,
    required this.otherUserId,
    required this.otherUserName,
    this.createdAtMillis,
    this.acceptedAtMillis,
    this.endedAtMillis,
    this.ringExpiresAtMillis,
    this.expiresAtMillis,
  });

  final String callId;
  final String role;
  final String status;
  final String otherUserId;
  final String otherUserName;
  final int? createdAtMillis;
  final int? acceptedAtMillis;
  final int? endedAtMillis;
  final int? ringExpiresAtMillis;
  final int? expiresAtMillis;

  bool get isCaller => role == 'caller';
  bool get isCallee => role == 'callee';
  bool get isRinging => status == 'ringing';
  bool get isAccepted => status == 'accepted';
  bool get isTerminal =>
      status == 'declined' ||
      status == 'ended' ||
      status == 'missed' ||
      status == 'expired';

  factory AudioCallR2Session.fromMap(Map<dynamic, dynamic> data) {
    int? intValue(String key) {
      final value = data[key];
      return value is num ? value.toInt() : null;
    }

    final otherName = data['otherUserName']?.toString().trim() ?? '';
    return AudioCallR2Session(
      callId: data['callId']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      otherUserId: data['otherUserId']?.toString() ?? '',
      otherUserName: otherName.isEmpty ? 'NearMeU user' : otherName,
      createdAtMillis: intValue('createdAtMillis'),
      acceptedAtMillis: intValue('acceptedAtMillis'),
      endedAtMillis: intValue('endedAtMillis'),
      ringExpiresAtMillis: intValue('ringExpiresAtMillis'),
      expiresAtMillis: intValue('expiresAtMillis'),
    );
  }
}

class IncomingAudioCallR2 {
  const IncomingAudioCallR2({
    required this.callId,
    required this.callerUid,
    required this.callerName,
    required this.ringExpiresAtMillis,
  });

  final String callId;
  final String callerUid;
  final String callerName;
  final int ringExpiresAtMillis;

  factory IncomingAudioCallR2.fromMap(Map<dynamic, dynamic> data) {
    final expiry = data['ringExpiresAtMillis'];
    final name = data['callerName']?.toString().trim() ?? '';
    return IncomingAudioCallR2(
      callId: data['callId']?.toString() ?? '',
      callerUid: data['callerUid']?.toString() ?? '',
      callerName: name.isEmpty ? 'NearMeU user' : name,
      ringExpiresAtMillis: expiry is num ? expiry.toInt() : 0,
    );
  }

  bool get isValid =>
      callId.isNotEmpty &&
      callerUid.isNotEmpty &&
      ringExpiresAtMillis > DateTime.now().millisecondsSinceEpoch;
}

class AudioRtcAccessR2 {
  const AudioRtcAccessR2({
    required this.callId,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.agoraUid,
    required this.tokenExpiresAtMillis,
  });

  final String callId;
  final String appId;
  final String channelName;
  final String token;
  final int agoraUid;
  final int tokenExpiresAtMillis;

  factory AudioRtcAccessR2.fromMap(Map<dynamic, dynamic> data) {
    final uid = data['agoraUid'];
    final expiry = data['tokenExpiresAtMillis'];
    return AudioRtcAccessR2(
      callId: data['callId']?.toString() ?? '',
      appId: data['appId']?.toString() ?? '',
      channelName: data['channelName']?.toString() ?? '',
      token: data['token']?.toString() ?? '',
      agoraUid: uid is num ? uid.toInt() : 0,
      tokenExpiresAtMillis: expiry is num ? expiry.toInt() : 0,
    );
  }

  bool get isValid =>
      callId.isNotEmpty &&
      appId.isNotEmpty &&
      channelName.isNotEmpty &&
      token.isNotEmpty &&
      agoraUid > 0 &&
      tokenExpiresAtMillis > DateTime.now().millisecondsSinceEpoch;
}

class AudioCallR2Exception implements Exception {
  const AudioCallR2Exception(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AudioCallR2Service {
  AudioCallR2Service({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<AudioCallR2Session> startCall(String calleeUid) {
    return _sessionCall(
      'startAudioCallR2',
      <String, dynamic>{'calleeUid': calleeUid},
    );
  }

  Future<AudioCallR2Session> getCall(String callId) {
    return _sessionCall(
      'getAudioCallR2',
      <String, dynamic>{'callId': callId},
    );
  }

  Future<AudioCallR2Session> respond({
    required String callId,
    required bool accept,
  }) {
    return _sessionCall(
      'respondAudioCallR2',
      <String, dynamic>{
        'callId': callId,
        'action': accept ? 'accept' : 'decline',
      },
    );
  }

  Future<IncomingAudioCallR2?> getIncomingCall() async {
    try {
      final result = await _functions
          .httpsCallable('getIncomingAudioCallR2')
          .call<dynamic>();
      final payload = result.data;
      if (payload == null) return null;
      if (payload is! Map) return null;
      final incoming = IncomingAudioCallR2.fromMap(payload);
      return incoming.isValid ? incoming : null;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'unauthenticated') return null;
      throw _mapException(error);
    }
  }

  Future<AudioRtcAccessR2> getRtcAccess(String callId) async {
    try {
      final result = await _functions
          .httpsCallable('getAudioRtcAccessR2')
          .call<dynamic>(<String, dynamic>{'callId': callId});
      final payload = result.data;
      if (payload is! Map) {
        throw const AudioCallR2Exception('Audio access response was invalid.');
      }
      final access = AudioRtcAccessR2.fromMap(payload);
      if (!access.isValid) {
        throw const AudioCallR2Exception('Audio access response was incomplete.');
      }
      return access;
    } on FirebaseFunctionsException catch (error) {
      throw _mapException(error);
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await _functions.httpsCallable('endAudioCallR2').call<void>(
        <String, dynamic>{'callId': callId},
      );
    } on FirebaseFunctionsException catch (error) {
      throw _mapException(error);
    }
  }

  Future<AudioCallR2Session> _sessionCall(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<dynamic>(data);
      final payload = result.data;
      if (payload is! Map) {
        throw const AudioCallR2Exception('Audio call response was invalid.');
      }
      final session = AudioCallR2Session.fromMap(payload);
      if (session.callId.isEmpty || session.status.isEmpty) {
        throw const AudioCallR2Exception('Audio call response was incomplete.');
      }
      return session;
    } on FirebaseFunctionsException catch (error) {
      throw _mapException(error);
    }
  }

  AudioCallR2Exception _mapException(FirebaseFunctionsException error) {
    final details = error.details;
    final reason = details is Map ? details['reason']?.toString() : null;
    if (reason == 'premium-required') {
      return const AudioCallR2Exception(
        'Premium is required to start an audio call.',
        code: 'premium-required',
      );
    }
    if (reason == 'agora-credentials-invalid') {
      return const AudioCallR2Exception(
        'Audio calling is being configured. Please try again later.',
        code: 'agora-credentials-invalid',
      );
    }
    final message = error.message?.trim();
    return AudioCallR2Exception(
      message == null || message.isEmpty
          ? 'Audio call could not be completed.'
          : message,
      code: error.code,
    );
  }
}
