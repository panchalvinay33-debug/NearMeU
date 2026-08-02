import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/security/notification_route.dart';
import 'package:nearmeu/services/audio_call_service.dart';

void main() {
  group('audio call notification routing', () {
    const callId = 'Abcdefghijklmnopqrstuv12';

    test('maps remote data to an audio call destination', () {
      final destination = NotificationRoute.fromData(<String, dynamic>{
        'type': NotificationRoute.audioCallType,
        'callId': callId,
      });

      expect(destination, isNotNull);
      expect(destination!.isAudioCall, isTrue);
      expect(destination.value, callId);
      expect(destination.payload, 'call:$callId');
    });

    test('maps local payload to an audio call destination', () {
      final destination = NotificationRoute.fromPayload('call:$callId');
      expect(destination, isNotNull);
      expect(destination!.isAudioCall, isTrue);
      expect(destination.value, callId);
    });

    test('rejects malformed call ids', () {
      expect(
        NotificationRoute.fromData(<String, dynamic>{
          'type': NotificationRoute.audioCallType,
          'callId': 'bad/id',
        }),
        isNull,
      );
      expect(NotificationRoute.fromPayload('call:short'), isNull);
    });
  });

  group('audio call session', () {
    test('parses accepted RTC access', () {
      final session = AudioCallSession.fromMap(<String, dynamic>{
        'callId': 'Abcdefghijklmnopqrstuv12',
        'role': 'callee',
        'status': 'accepted',
        'otherUserId': 'caller',
        'otherUserName': 'Caller',
        'appId': 'app',
        'channelName': 'channel',
        'token': 'token',
        'agoraUid': 123,
      });

      expect(session.isCallee, isTrue);
      expect(session.isAccepted, isTrue);
      expect(session.hasRtcAccess, isTrue);
      expect(session.isTerminal, isFalse);
    });

    test('recognizes terminal calls without RTC access', () {
      final session = AudioCallSession.fromMap(<String, dynamic>{
        'callId': 'Abcdefghijklmnopqrstuv12',
        'role': 'caller',
        'status': 'declined',
        'otherUserId': 'callee',
        'otherUserName': 'Callee',
      });

      expect(session.isCaller, isTrue);
      expect(session.isTerminal, isTrue);
      expect(session.hasRtcAccess, isFalse);
    });
  });
}
