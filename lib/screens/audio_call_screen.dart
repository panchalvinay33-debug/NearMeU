import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/audio_call_model.dart';
import '../services/agora_audio_engine.dart';
import '../services/audio_call_service.dart';
import '../services/call_device_service.dart';
import '../theme/app_colors.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({
    super.key,
    this.initialSession,
    this.callId,
    required this.incoming,
  }) : assert(initialSession != null || callId != null);

  final AudioCallSessionPayload? initialSession;
  final String? callId;
  final bool incoming;

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with WidgetsBindingObserver {
  final AudioCallService _calls = AudioCallService();
  final AgoraAudioEngine _rtc = AgoraAudioEngine();
  final CallDeviceService _device = CallDeviceService();

  AudioCallSessionPayload? _session;
  StreamSubscription<AgoraAudioEvent>? _rtcSub;
  Timer? _pollTimer;
  Timer? _durationTimer;
  Timer? _deviceTimer;
  Duration _duration = Duration.zero;
  bool _busy = true;
  bool _muted = false;
  bool _speaker = false;
  bool _bluetoothAvailable = false;
  bool _bluetoothSelected = false;
  bool _remoteJoined = false;
  bool _closing = false;
  String? _error;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  AudioCallModel? get _call => _session?.call;
  bool get _isCaller => _call?.callerId == _currentUid;
  bool get _needsAnswer => widget.incoming && _call?.status == 'ringing';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final session =
          widget.initialSession ?? await _calls.getCall(widget.callId!);
      if (!mounted) return;
      setState(() {
        _session = session;
        _busy = false;
      });
      await _device.enterCallMode();
      await _refreshDeviceState();
      _deviceTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_refreshDeviceState()),
      );
      if (!widget.incoming || session.call.isConnected) {
        await _joinRtc(session);
      }
      _startPolling();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _refreshDeviceState() async {
    try {
      final available = await _device.bluetoothAvailable();
      final selected = await _device.bluetoothSelected();
      if (!mounted) return;
      setState(() {
        _bluetoothAvailable = available;
        _bluetoothSelected = selected;
        if (selected) _speaker = false;
      });
    } catch (_) {}
  }

  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _joinRtc(AudioCallSessionPayload session) async {
    final credentials = session.rtc;
    if (credentials == null || session.call.channelName.isEmpty) return;
    if (!await _ensureMicrophonePermission()) {
      if (mounted) {
        setState(
          () => _error = 'Microphone permission is required for calls.',
        );
      }
      return;
    }
    _rtcSub ??= _rtc.events.listen(_onRtcEvent);
    await _rtc.join(
      credentials: credentials,
      channelName: session.call.channelName,
    );
    await _device.setProximityEnabled(
      !_speaker && !_bluetoothSelected,
    );
  }

  void _onRtcEvent(AgoraAudioEvent event) {
    if (!mounted || _closing) return;
    if (event.type == 'remoteJoined') {
      setState(() => _remoteJoined = true);
      _startDurationTimer();
    } else if (event.type == 'remoteLeft') {
      unawaited(_finish('remote-left'));
    } else if (event.type == 'tokenExpiring') {
      unawaited(_refreshToken());
    } else if (event.type == 'error') {
      setState(() => _error = event.value ?? 'Call audio error');
    }
  }

  Future<void> _refreshToken() async {
    final call = _call;
    if (call == null || _closing) return;
    try {
      final latest = await _calls.getCall(call.callId);
      _session = latest;
      final token = latest.rtc?.token;
      if (token != null) await _rtc.renewToken(token);
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_poll()),
    );
  }

  Future<void> _poll() async {
    final call = _call;
    if (call == null || _closing) return;
    try {
      final latest = await _calls.getCall(call.callId);
      if (!mounted || _closing) return;
      setState(() => _session = latest);
      if (latest.call.isTerminal) {
        await _closeWithoutWrite();
        return;
      }
      if (latest.call.isConnected && !_rtc.joined && latest.rtc != null) {
        await _joinRtc(latest);
      }
    } catch (_) {}
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_closing) {
        setState(() => _duration += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _answer() async {
    final call = _call;
    if (call == null || _busy || _closing) return;
    setState(() => _busy = true);
    try {
      final session = await _calls.respond(callId: call.callId, accept: true);
      if (!mounted || _closing) return;
      setState(() => _session = session);
      await _joinRtc(session);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted && !_closing) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final call = _call;
    if (call == null || _closing) return;
    try {
      await _calls.respond(callId: call.callId, accept: false);
    } catch (_) {}
    await _closeWithoutWrite();
  }

  Future<void> _finish(String reason) async {
    if (_closing) return;
    final call = _call;
    if (call != null) {
      try {
        await _calls.endCall(call.callId, reason: reason);
      } catch (_) {}
    }
    await _closeWithoutWrite();
  }

  Future<void> _closeWithoutWrite() async {
    if (_closing) return;
    _closing = true;
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    _deviceTimer?.cancel();
    await _rtc.leave();
    try {
      await _device.setProximityEnabled(false);
    } catch (_) {}
    try {
      await _device.leaveCallMode();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    final value = await _rtc.toggleMute();
    if (mounted) setState(() => _muted = value);
  }

  Future<void> _toggleSpeaker() async {
    if (_closing) return;
    if (_bluetoothSelected) {
      await _device.setBluetooth(false);
      _bluetoothSelected = false;
    }
    final value = await _rtc.toggleSpeaker();
    await _device.setSpeaker(value);
    await _device.setProximityEnabled(!value);
    if (mounted) {
      setState(() {
        _speaker = value;
        if (value) _bluetoothSelected = false;
      });
    }
  }

  Future<void> _toggleBluetooth() async {
    if (_closing) return;
    if (!_bluetoothSelected) {
      final permission = await Permission.bluetoothConnect.request();
      if (!permission.isGranted && !permission.isLimited) {
        if (mounted) {
          setState(
            () => _error = 'Bluetooth permission is required to use a headset.',
          );
        }
        return;
      }
    }

    final target = !_bluetoothSelected;
    final routed = await _device.setBluetooth(target);
    if (target && !routed) {
      if (mounted) {
        setState(() => _error = 'No Bluetooth call device is available.');
      }
      return;
    }
    if (target && _speaker) {
      await _rtc.toggleSpeaker();
      _speaker = false;
    }
    await _device.setProximityEnabled(!target && !_speaker);
    if (mounted) {
      setState(() {
        _bluetoothSelected = target;
        if (target) _speaker = false;
        _error = null;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_poll());
      unawaited(_refreshDeviceState());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    _deviceTimer?.cancel();
    _rtcSub?.cancel();
    unawaited(_rtc.dispose());
    unawaited(_device.leaveCallMode());
    super.dispose();
  }

  String _durationLabel() {
    final minutes = _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _statusText() {
    final call = _call;
    if (call == null) return 'Preparing call...';
    if (_error != null) return _error!;
    if (_needsAnswer) return 'Incoming audio call';
    if (call.status == 'ringing') {
      return _isCaller ? 'Ringing...' : 'Incoming call';
    }
    if (call.status == 'connected') {
      return _remoteJoined ? _durationLabel() : 'Connecting audio...';
    }
    return call.status;
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    final otherName = call?.otherUserName(_currentUid) ?? 'NearMeU User';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_finish('back-button'));
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 58,
                  backgroundColor: AppColors.primary.withValues(alpha: .18),
                  child: Text(
                    otherName.isEmpty ? '?' : otherName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  otherName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _statusText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _error == null
                        ? AppColors.textSecondary
                        : Colors.redAccent,
                    fontSize: 15,
                  ),
                ),
                if (_bluetoothAvailable) ...[
                  const SizedBox(height: 8),
                  Text(
                    _bluetoothSelected
                        ? 'Bluetooth audio connected'
                        : 'Bluetooth device available',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  )
                else if (_needsAnswer)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _roundButton(
                        Icons.call_end_rounded,
                        Colors.redAccent,
                        _reject,
                        'Reject',
                      ),
                      _roundButton(
                        Icons.call_rounded,
                        Colors.green,
                        _answer,
                        'Accept',
                      ),
                    ],
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 22,
                    runSpacing: 18,
                    children: [
                      _roundButton(
                        _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        AppColors.surface,
                        _toggleMute,
                        _muted ? 'Unmute' : 'Mute',
                      ),
                      _roundButton(
                        _speaker
                            ? Icons.volume_up_rounded
                            : Icons.hearing_rounded,
                        AppColors.surface,
                        _toggleSpeaker,
                        _speaker ? 'Earpiece' : 'Speaker',
                      ),
                      if (_bluetoothAvailable)
                        _roundButton(
                          Icons.bluetooth_audio_rounded,
                          _bluetoothSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          _toggleBluetooth,
                          _bluetoothSelected ? 'Bluetooth' : 'Bluetooth',
                        ),
                      _roundButton(
                        Icons.call_end_rounded,
                        Colors.redAccent,
                        () => _finish('user-ended'),
                        'End',
                      ),
                    ],
                  ),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundButton(
    IconData icon,
    Color background,
    VoidCallback onTap,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
