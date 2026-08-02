import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../services/audio_call_service.dart';
import '../theme/app_colors.dart';

class AudioCallScreen extends StatefulWidget {
  AudioCallScreen.outgoing({
    super.key,
    required AudioCallSession session,
  }) : initialSession = session,
       callId = session.callId,
       incoming = false;

  const AudioCallScreen.incoming({
    super.key,
    required this.callId,
  }) : initialSession = null,
       incoming = true;

  final AudioCallSession? initialSession;
  final String callId;
  final bool incoming;

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with WidgetsBindingObserver {
  final AudioCallService _service = AudioCallService();
  final AudioRecorder _permissionRecorder = AudioRecorder();

  AudioCallSession? _session;
  RtcEngine? _engine;
  RtcEngineEventHandler? _handler;
  Timer? _pollTimer;
  Timer? _durationTimer;
  bool _loading = true;
  bool _answering = false;
  bool _ending = false;
  bool _engineJoining = false;
  bool _localJoined = false;
  bool _remoteJoined = false;
  bool _muted = false;
  bool _speakerOn = true;
  String? _error;
  Duration _connectedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.initialSession;
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      var session = _session ?? await _service.getCall(widget.callId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });

      if (session.isTerminal) {
        _scheduleClose();
        return;
      }

      if (!widget.incoming && session.hasRtcAccess) {
        await _joinAgora(session);
      } else if (session.isAccepted && session.hasRtcAccess) {
        await _joinAgora(session);
      }

      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_refreshCall()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _refreshCall() async {
    if (_ending) return;
    try {
      final latest = await _service.getCall(widget.callId);
      if (!mounted) return;
      final previousStatus = _session?.status;
      setState(() => _session = latest);

      if (latest.isTerminal) {
        await _leaveAgora();
        _scheduleClose();
        return;
      }
      if (latest.isAccepted && !_engineJoining && _engine == null) {
        await _joinAgora(latest);
      }
      if (previousStatus != latest.status && latest.isAccepted) {
        _startDurationTimer();
      }
    } catch (error) {
      if (!mounted || _ending) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _accept() async {
    if (_answering || _ending) return;
    setState(() => _answering = true);
    try {
      final session = await _service.respond(
        callId: widget.callId,
        accept: true,
      );
      if (!mounted) return;
      setState(() => _session = session);
      if (session.hasRtcAccess) await _joinAgora(session);
      _startDurationTimer();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _answering = false);
    }
  }

  Future<void> _decline() async {
    if (_answering || _ending) return;
    setState(() => _answering = true);
    try {
      await _service.respond(callId: widget.callId, accept: false);
    } catch (_) {
      // A simultaneous caller cancel or timeout is equivalent to a decline here.
    } finally {
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _joinAgora(AudioCallSession session) async {
    if (_engine != null || _engineJoining || !session.hasRtcAccess) return;
    _engineJoining = true;
    try {
      final permission = await _permissionRecorder.hasPermission();
      if (!permission) {
        throw const AudioCallException(
          'Microphone permission is required for audio calls.',
        );
      }

      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: session.appId!,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      final handler = RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (!mounted) return;
          setState(() => _localJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) return;
          setState(() => _remoteJoined = true);
          _startDurationTimer();
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) return;
          setState(() => _remoteJoined = false);
          unawaited(_endCall(remoteEnded: true));
        },
        onConnectionStateChanged: (connection, state, reason) {
          if (!mounted) return;
          if (state == ConnectionStateType.connectionStateFailed) {
            setState(() => _error = 'Call connection failed. Please try again.');
          }
        },
        onError: (errorCode, message) {
          if (!mounted) return;
          setState(
            () => _error = message.trim().isNotEmpty
                ? message.trim()
                : 'Audio engine error: ${errorCode.name}',
          );
        },
      );
      engine.registerEventHandler(handler);
      await engine.enableAudio();
      await engine.disableVideo();
      await engine.setDefaultAudioRouteToSpeakerphone(true);
      await engine.setEnableSpeakerphone(true);
      await engine.joinChannel(
        token: session.token!,
        channelId: session.channelName!,
        uid: session.agoraUid!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          enableAudioRecordingOrPlayout: true,
        ),
      );
      _engine = engine;
      _handler = handler;
    } catch (error) {
      await _leaveAgora();
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _engineJoining = false;
    }
  }

  Future<void> _toggleMute() async {
    final engine = _engine;
    if (engine == null) return;
    final next = !_muted;
    await engine.muteLocalAudioStream(next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _toggleSpeaker() async {
    final engine = _engine;
    if (engine == null) return;
    final next = !_speakerOn;
    await engine.setEnableSpeakerphone(next);
    if (mounted) setState(() => _speakerOn = next);
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_remoteJoined) return;
      setState(() {
        _connectedDuration += const Duration(seconds: 1);
      });
    });
  }

  String _durationText() {
    final total = _connectedDuration.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _statusText() {
    final session = _session;
    if (session == null) return 'Connecting…';
    if (session.status == 'ringing') {
      return session.isCaller ? 'Ringing…' : 'Incoming audio call';
    }
    if (session.status == 'accepted') {
      if (_remoteJoined) return _durationText();
      if (_localJoined) return 'Connecting to ${session.otherUserName}…';
      return 'Joining secure audio…';
    }
    if (session.status == 'declined') return 'Call declined';
    if (session.status == 'missed') return 'Missed call';
    if (session.status == 'expired') return 'Call expired';
    return 'Call ended';
  }

  Future<void> _endCall({bool remoteEnded = false}) async {
    if (_ending) return;
    _ending = true;
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    await _leaveAgora();
    if (!remoteEnded) {
      try {
        await _service.endCall(widget.callId);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _leaveAgora() async {
    final engine = _engine;
    _engine = null;
    final handler = _handler;
    _handler = null;
    _localJoined = false;
    _remoteJoined = false;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
      if (handler != null) engine.unregisterEventHandler(handler);
      await engine.release();
    } catch (_) {}
  }

  void _scheduleClose() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_endCall());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    unawaited(_leaveAgora());
    unawaited(_permissionRecorder.dispose());
    super.dispose();
  }

  Widget _roundControl({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool active = false,
    bool destructive = false,
  }) {
    final background = destructive
        ? Colors.redAccent
        : active
        ? AppColors.primary
        : AppColors.surface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final isIncomingRinging =
        widget.incoming && session?.isCallee == true && session?.isRinging == true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_endCall());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    session?.otherUserName.isNotEmpty == true
                        ? session!.otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  session?.otherUserName ?? 'NearMeU user',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loading ? 'Loading call…' : _statusText(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const Spacer(),
                if (isIncomingRinging)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _roundControl(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        destructive: true,
                        onPressed: _answering ? null : () => unawaited(_decline()),
                      ),
                      _roundControl(
                        icon: Icons.call_rounded,
                        label: 'Accept',
                        active: true,
                        onPressed: _answering ? null : () => unawaited(_accept()),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _roundControl(
                        icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _muted ? 'Unmute' : 'Mute',
                        active: _muted,
                        onPressed: _engine == null
                            ? null
                            : () => unawaited(_toggleMute()),
                      ),
                      _roundControl(
                        icon: Icons.call_end_rounded,
                        label: 'End',
                        destructive: true,
                        onPressed: _ending ? null : () => unawaited(_endCall()),
                      ),
                      _roundControl(
                        icon: _speakerOn
                            ? Icons.volume_up_rounded
                            : Icons.hearing_rounded,
                        label: 'Speaker',
                        active: _speakerOn,
                        onPressed: _engine == null
                            ? null
                            : () => unawaited(_toggleSpeaker()),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
