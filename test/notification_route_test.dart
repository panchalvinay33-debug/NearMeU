import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/security/notification_route.dart';

void main() {
  group('notification route validation', () {
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

    test('parses chat and support announcement destinations', () {
      final chat = NotificationRoute.fromData(const {
        'type': NotificationRoute.privateChatType,
        'chatId': 'alice_bob',
      });
      expect(chat?.isPrivateChat, isTrue);
      expect(chat?.value, 'alice_bob');
      expect(chat?.payload, 'chat:alice_bob');

      final announcement = NotificationRoute.fromData(const {
        'type': NotificationRoute.supportAnnouncementType,
        'announcementId': 'announcement_1',
      });
      expect(announcement?.isSupportAnnouncement, isTrue);
      expect(announcement?.payload, 'support:announcements');

      expect(
        NotificationRoute.fromPayload('support:announcements')
            ?.isSupportAnnouncement,
        isTrue,
      );
      expect(NotificationRoute.fromPayload('chat: alice_bob ')?.value, 'alice_bob');
      expect(NotificationRoute.fromPayload('unknown:value'), isNull);
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
