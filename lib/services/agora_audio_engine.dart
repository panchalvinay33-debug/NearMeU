import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../models/audio_call_model.dart';

class AgoraAudioEngine {
  RtcEngine? _engine;
  final StreamController<AgoraAudioEvent> _events =
      StreamController<AgoraAudioEvent>.broadcast();

  Stream<AgoraAudioEvent> get events => _events.stream;
  bool _joined = false;
  bool _muted = false;
  bool _speakerEnabled = false;

  bool get joined => _joined;
  bool get muted => _muted;
  bool get speakerEnabled => _speakerEnabled;

  Future<void> join({
    required AgoraRtcCredentials credentials,
    required String channelName,
  }) async {
    await leave();
    final engine = createAgoraRtcEngine();
    _engine = engine;
    await engine.initialize(
      RtcEngineContext(
        appId: credentials.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        audioScenario: AudioScenarioType.audioScenarioDefault,
      ),
    );
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _joined = true;
          _events.add(const AgoraAudioEvent.joined());
        },
        onRejoinChannelSuccess: (connection, elapsed) {
          _joined = true;
          _events.add(const AgoraAudioEvent.rejoined());
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _events.add(AgoraAudioEvent.remoteJoined(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) {
          _events.add(AgoraAudioEvent.remoteLeft(remoteUid));
        },
        onConnectionLost: (connection) {
          _events.add(const AgoraAudioEvent.connectionLost());
        },
        onConnectionStateChanged: (connection, state, reason) {
          _events.add(AgoraAudioEvent.connectionState(state.name));
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          _events.add(const AgoraAudioEvent.tokenExpiring());
        },
        onError: (errorCode, message) {
          _events.add(AgoraAudioEvent.error('$errorCode: $message'));
        },
      ),
    );
    await engine.enableAudio();
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioDefault,
    );
    await engine.setDefaultAudioRouteToSpeakerphone(false);
    await engine.setEnableSpeakerphone(false);
    _speakerEnabled = false;
    await engine.joinChannelWithUserAccount(
      token: credentials.token,
      channelId: channelName,
      userAccount: credentials.userAccount,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> renewToken(String token) async {
    final engine = _engine;
    if (engine == null || token.isEmpty) return;
    await engine.renewToken(token);
  }

  Future<bool> toggleMute() async {
    final engine = _engine;
    if (engine == null) return _muted;
    _muted = !_muted;
    await engine.muteLocalAudioStream(_muted);
    return _muted;
  }

  Future<bool> toggleSpeaker() async {
    final engine = _engine;
    if (engine == null) return _speakerEnabled;
    _speakerEnabled = !_speakerEnabled;
    await engine.setEnableSpeakerphone(_speakerEnabled);
    return _speakerEnabled;
  }

  Future<void> setSpeaker(bool enabled) async {
    final engine = _engine;
    if (engine == null) return;
    _speakerEnabled = enabled;
    await engine.setEnableSpeakerphone(enabled);
  }

  Future<void> leave() async {
    final engine = _engine;
    _engine = null;
    _joined = false;
    _muted = false;
    _speakerEnabled = false;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}
    try {
      engine.release(sync: true);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await leave();
    await _events.close();
  }
}

class AgoraAudioEvent {
  const AgoraAudioEvent._(this.type, [this.value]);

  const AgoraAudioEvent.joined() : this._('joined');
  const AgoraAudioEvent.rejoined() : this._('rejoined');
  const AgoraAudioEvent.connectionLost() : this._('connectionLost');
  const AgoraAudioEvent.tokenExpiring() : this._('tokenExpiring');
  AgoraAudioEvent.remoteJoined(int uid) : this._('remoteJoined', '$uid');
  AgoraAudioEvent.remoteLeft(int uid) : this._('remoteLeft', '$uid');
  AgoraAudioEvent.connectionState(String value) : this._('connectionState', value);
  AgoraAudioEvent.error(String value) : this._('error', value);

  final String type;
  final String? value;
}
