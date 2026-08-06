class AudioCallModel {
  const AudioCallModel({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
    required this.calleeName,
    required this.status,
    required this.channelName,
    this.createdAtMs,
    this.answeredAtMs,
    this.endedAtMs,
    this.expiresAtMs,
    this.endedBy,
    this.endReason,
  });

  final String callId;
  final String callerId;
  final String calleeId;
  final String callerName;
  final String calleeName;
  final String status;
  final String channelName;
  final int? createdAtMs;
  final int? answeredAtMs;
  final int? endedAtMs;
  final int? expiresAtMs;
  final String? endedBy;
  final String? endReason;

  bool get isRinging => status == 'ringing';
  bool get isConnected => status == 'connected';
  bool get isTerminal => const {
        'ended', 'rejected', 'missed', 'failed', 'cancelled',
      }.contains(status);

  String otherUserId(String currentUid) =>
      currentUid == callerId ? calleeId : callerId;

  String otherUserName(String currentUid) =>
      currentUid == callerId ? calleeName : callerName;

  factory AudioCallModel.fromMap(Map<String, dynamic> map) {
    int? asInt(dynamic value) => value is int ? value : (value is num ? value.toInt() : null);
    return AudioCallModel(
      callId: (map['callId'] as String? ?? '').trim(),
      callerId: (map['callerId'] as String? ?? '').trim(),
      calleeId: (map['calleeId'] as String? ?? '').trim(),
      callerName: (map['callerName'] as String? ?? 'NearMeU User').trim(),
      calleeName: (map['calleeName'] as String? ?? 'NearMeU User').trim(),
      status: (map['status'] as String? ?? 'unknown').trim(),
      channelName: (map['channelName'] as String? ?? '').trim(),
      createdAtMs: asInt(map['createdAtMs']),
      answeredAtMs: asInt(map['answeredAtMs']),
      endedAtMs: asInt(map['endedAtMs']),
      expiresAtMs: asInt(map['expiresAtMs']),
      endedBy: map['endedBy'] as String?,
      endReason: map['endReason'] as String?,
    );
  }
}

class AgoraRtcCredentials {
  const AgoraRtcCredentials({
    required this.appId,
    required this.token,
    required this.userAccount,
    required this.tokenExpiresInSeconds,
  });

  final String appId;
  final String token;
  final String userAccount;
  final int tokenExpiresInSeconds;

  factory AgoraRtcCredentials.fromMap(Map<String, dynamic> map) {
    return AgoraRtcCredentials(
      appId: (map['appId'] as String? ?? '').trim(),
      token: (map['token'] as String? ?? '').trim(),
      userAccount: (map['userAccount'] as String? ?? '').trim(),
      tokenExpiresInSeconds: (map['tokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class AudioCallSessionPayload {
  const AudioCallSessionPayload({required this.call, this.rtc});
  final AudioCallModel call;
  final AgoraRtcCredentials? rtc;
}
