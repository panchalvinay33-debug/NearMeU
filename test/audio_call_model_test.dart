import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/audio_call_model.dart';

void main() {
  group('AudioCallModel', () {
    test('parses active call and resolves counterpart', () {
      final call = AudioCallModel.fromMap(const <String, dynamic>{
        'callId': 'call-1',
        'callerId': 'alice',
        'calleeId': 'bob',
        'callerName': 'Alice',
        'calleeName': 'Bob',
        'status': 'connected',
        'channelName': 'nmu_call-1',
        'createdAtMs': 1000,
        'answeredAtMs': 2000,
      });

      expect(call.isConnected, isTrue);
      expect(call.isTerminal, isFalse);
      expect(call.otherUserId('alice'), 'bob');
      expect(call.otherUserName('bob'), 'Alice');
    });

    test('recognizes every terminal Batch09 state', () {
      for (final status in const <String>[
        'ended',
        'rejected',
        'missed',
        'failed',
        'cancelled',
      ]) {
        final call = AudioCallModel.fromMap(<String, dynamic>{
          'callId': 'call-$status',
          'callerId': 'alice',
          'calleeId': 'bob',
          'callerName': 'Alice',
          'calleeName': 'Bob',
          'status': status,
          'channelName': 'nmu_$status',
        });
        expect(call.isTerminal, isTrue, reason: status);
      }
    });
  });

  test('AgoraRtcCredentials parses bounded server payload fields', () {
    final rtc = AgoraRtcCredentials.fromMap(const <String, dynamic>{
      'appId': 'app-id',
      'token': 'rtc-token',
      'userAccount': 'alice',
      'tokenExpiresInSeconds': 900,
    });

    expect(rtc.appId, 'app-id');
    expect(rtc.token, 'rtc-token');
    expect(rtc.userAccount, 'alice');
    expect(rtc.tokenExpiresInSeconds, 900);
  });
}
