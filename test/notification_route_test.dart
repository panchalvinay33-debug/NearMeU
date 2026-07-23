import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/security/notification_route.dart';

void main() {
  group('notification chat route validation', () {
    test('accepts only bounded private-chat payloads', () {
      expect(
        NotificationRoute.chatIdFromData(const {
          'type': NotificationRoute.privateChatType,
          'chatId': 'alice_bob',
        }),
        'alice_bob',
      );
      expect(
        NotificationRoute.chatIdFromData(const {
          'type': 'chat',
          'chatId': 'alice_bob',
        }),
        isNull,
      );
      expect(
        NotificationRoute.chatIdFromData(const {
          'type': NotificationRoute.privateChatType,
          'chatId': '',
        }),
        isNull,
      );
      expect(
        NotificationRoute.chatIdFromData({
          'type': NotificationRoute.privateChatType,
          'chatId': 'x' * (NotificationRoute.maximumChatIdLength + 1),
        }),
        isNull,
      );
    });

    test('normalizes local notification payloads', () {
      expect(NotificationRoute.normalizedChatId(' alice_bob '), 'alice_bob');
      expect(NotificationRoute.normalizedChatId(null), isNull);
      expect(NotificationRoute.normalizedChatId('   '), isNull);
    });

    test('resolves only the other member of a two-person chat', () {
      expect(
        NotificationRoute.otherParticipant(
          currentUid: 'alice',
          participants: const ['alice', 'bob'],
        ),
        'bob',
      );
      expect(
        NotificationRoute.otherParticipant(
          currentUid: 'mallory',
          participants: const ['alice', 'bob'],
        ),
        isNull,
      );
      expect(
        NotificationRoute.otherParticipant(
          currentUid: 'alice',
          participants: const ['alice', 'alice'],
        ),
        isNull,
      );
      expect(
        NotificationRoute.otherParticipant(
          currentUid: 'alice',
          participants: const ['alice', 'bob', 'charlie'],
        ),
        isNull,
      );
    });
  });
}
