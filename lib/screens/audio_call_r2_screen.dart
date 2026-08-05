import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../services/audio_call_r2_service.dart';
import '../theme/app_colors.dart';

class AudioCallR2Screen extends StatefulWidget {
  const AudioCallR2Screen.outgoing({
    super.key,
    required AudioCallR2Session session,
  }) : initialSession = session,
       callId = session.callId,
       incoming = false;

  const AudioCallR2Screen.incoming({
    super.key,
    required this.callId,
  }) : initialSession = null,
       incoming = true;

  final AudioCallR2Session? initialSession;
  final String callId;
  final bool incoming;

  @override
  State<AudioCallR2Screen> createState() => _AudioCallR2ScreenState();
}

class _AudioCallR2ScreenState extends State<AudioCallR2Screen> {
  final AudioCallR2Service _service = AudioCallR2Service();
  final AudioRecorder _permissionRecorder = AudioRecorder();

  AudioCallR2Session? _session;
  RtcEngine? _engine;
  Timer? _pollTimer;
  Timer? _closeTimer;
  bool _loading = true;
  bool _joining = false;
  bool _ending = false;
  bool _answering = false;
  bool _localJoined = false;
  bool _remoteJoined = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final session = _session ?? await _service.getCall(widget.callId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });

      if (session.isTerminal) {
        _scheduleClose();
        return;
      }

      if (session.isCaller || session.isAccepted) {
        await _joinRtc();
      }

      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_refresh()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _refresh() async {
    if (_ending) return;
    try {
      final latest = await _service.getCall(widget.callId);
      if (!mounted) return;
      setState(() => _session = latest);
      if (latest.isTerminal) {
        await _leaveRtc();
        _scheduleClose();
        return;
      }
      if (latest.isAccepted && _engine == null && !_joining) {
        await _joinRtc();
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
      await _joinRtc();
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
      // A simultaneous caller cancel or timeout is equivalent here.
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _joinRtc() async {
    if (_engine != null || _joining || _ending) return;
    _joining = true;
    try {
      final allowed = await _permissionRecorder.hasPermission();
      if (!allowed) {
        throw const AudioCallR2Exception(
          'Microphone permission is required for audio calls.',
        );
      }

      final access = await _service.getRtcAccess(widget.callId);
      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: access.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (!mounted || _ending) return;
            setState(() => _localJoined = true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!mounted || _ending) return;
            setState(() => _remoteJoined = true);
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted || _ending) return;
            setState(() => _remoteJoined = false);
            unawaited(_endCall(remoteEnded: true));
          },
          onError: (errorCode, message) {
            if (!mounted || _ending) return;
            final text = message.trim();
            setState(() {
              _error = text.isEmpty
                  ? 'Audio engine error: ${errorCode.name}'
                  : text;
            });
          },
        ),
      );
      await engine.enableAudio();
      await engine.disableVideo();
      await engine.setDefaultAudioRouteToSpeakerphone(true);
      await engine.setEnableSpeakerphone(true);
      _engine = engine;
      await engine.joinChannel(
        token: access.token,
        channelId: access.channelName,
        uid: access.agoraUid,
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
    } catch (error) {
      await _leaveRtc();
      if (mounted && !_ending) setState(() => _error = error.toString());
    } finally {
      _joining = false;
    }
  }

  Future<void> _endCall({bool remoteEnded = false}) async {
    if (_ending) return;
    _ending = true;
    _pollTimer?.cancel();
    await _leaveRtc();
    if (!remoteEnded) {
      try {
        await _service.endCall(widget.callId);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _leaveRtc() async {
    final engine = _engine;
    _engine = null;
    _localJoined = false;
    _remoteJoined = false;
    if (engine == null) return;
    try {
      await engine.leaveChannel().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await engine.release().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  void _scheduleClose() {
    _closeTimer ??= Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _statusText() {
    final session = _session;
    if (session == null) return 'Connecting…';
    if (session.isRinging) {
      return session.isCaller ? 'Ringing…' : 'Incoming audio call';
    }
    if (session.isAccepted) {
      if (_remoteJoined) return 'Connected';
      if (_localJoined) return 'Waiting for ${session.otherUserName}…';
      return 'Joining secure audio…';
    }
    if (session.status == 'declined') return 'Call declined';
    if (session.status == 'missed') return 'Missed call';
    if (session.status == 'expired') return 'Call expired';
    return 'Call ended';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _closeTimer?.cancel();
    unawaited(_leaveRtc());
    unawaited(_permissionRecorder.dispose());
    super.dispose();
  }

  Widget _callButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 32),
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
    final incomingRinging =
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
                if (incomingRinging)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _callButton(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        color: Colors.redAccent,
                        onPressed: _answering ? null : () => unawaited(_decline()),
                      ),
                      _callButton(
                        icon: Icons.call_rounded,
                        label: 'Accept',
                        color: AppColors.primary,
                        onPressed: _answering ? null : () => unawaited(_accept()),
                      ),
                    ],
                  )
                else
                  _callButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    color: Colors.redAccent,
                    onPressed: _ending ? null : () => unawaited(_endCall()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
