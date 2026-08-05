import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/services/audio_call_r2_service.dart';

void main() {
  test('R2 session parses lifecycle state safely', () {
    final session = AudioCallR2Session.fromMap(<String, dynamic>{
      'callId': 'r2_1234567890_abcd1234',
      'role': 'callee',
      'status': 'ringing',
      'otherUserId': 'caller-1',
      'otherUserName': 'Caller',
      'ringExpiresAtMillis': 123,
    });

    expect(session.callId, 'r2_1234567890_abcd1234');
    expect(session.isCallee, isTrue);
    expect(session.isRinging, isTrue);
    expect(session.isTerminal, isFalse);
  });

  test('RTC access rejects incomplete credentials', () {
    final access = AudioRtcAccessR2.fromMap(<String, dynamic>{
      'callId': 'r2_1234567890_abcd1234',
      'appId': '',
      'channelName': 'nearmeu_r2_test',
      'token': 'token',
      'agoraUid': 11,
      'tokenExpiresAtMillis':
          DateTime.now().millisecondsSinceEpoch + const Duration(hours: 1).inMilliseconds,
    });

    expect(access.isValid, isFalse);
  });

  test('client uses only R2 callable names', () {
    final source = File('lib/services/audio_call_r2_service.dart').readAsStringSync();
    for (final name in <String>[
      'startAudioCallR2',
      'getAudioCallR2',
      'respondAudioCallR2',
      'endAudioCallR2',
      'getAudioRtcAccessR2',
      'getIncomingAudioCallR2',
    ]) {
      expect(source, contains(name));
    }
    expect(source, isNot(contains("'startAudioCall'")));
    expect(source, isNot(contains("'getAudioCall'")));
  });

  test('foreground lifecycle stays separate from notifications and history', () {
    final source = File(
      'lib/widgets/audio_call_r2_foreground_lifecycle.dart',
    ).readAsStringSync();
    expect(source, contains('AudioCallR2Screen.incoming'));
    expect(source, contains('authStateChanges'));
    expect(source, isNot(contains('FirebaseMessaging')));
    expect(source, isNot(contains('flutter_local_notifications')));
    expect(source, isNot(contains('callHistory')));
  });
}
