import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/security/chat_security.dart';
import 'package:nearmeu/services/validation_service.dart';
import 'package:nearmeu/utils/date_formatters.dart';

void main() {
  group('age validation', () {
    test('rejects underage, over 99, decimal, negative, empty, and text', () {
      for (final value in ['17', '100', '18.5', '-18', '', 'abc']) {
        expect(
          () => ValidationService.ageText(value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('accepts boundary ages 18 and 99 as integers', () {
      expect(ValidationService.ageText(' 18 '), 18);
      expect(ValidationService.ageText('99'), 99);
    });
  });

  group('chat security', () {
    test('generates stable sorted chat ids', () {
      final security = ChatSecurity();
      expect(security.chatIdFor('b_user', 'a_user'), 'a_user_b_user');
      expect(security.chatIdFor('a_user', 'b_user'), 'a_user_b_user');
    });

    test('blocks self chat, empty messages, and long messages', () {
      final security = ChatSecurity();
      expect(
        () => security.chatIdFor('same', 'same'),
        throwsA(isA<ChatSecurityException>()),
      );
      expect(
        () => security.validateOutgoingMessage(
          senderId: 'a',
          receiverId: 'b',
          text: '   ',
        ),
        throwsA(isA<ChatSecurityException>()),
      );
      expect(
        () => security.validateOutgoingMessage(
          senderId: 'a',
          receiverId: 'b',
          text: 'x' * (ChatSecurity.maxMessageLength + 1),
        ),
        throwsA(isA<ChatSecurityException>()),
      );
    });
  });

  test('formats chat preview timestamps consistently', () {
    final now = DateTime(2026, 7, 21, 15, 30);
    expect(
      DateFormatters.chatPreview(DateTime(2026, 7, 21, 9, 5), now: now),
      '9:05 AM',
    );
    expect(
      DateFormatters.chatPreview(DateTime(2026, 7, 20, 9), now: now),
      'Yesterday',
    );
  });
}
