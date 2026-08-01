import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/message_model.dart';

MessageModel _mediaMessage({
  required DateTime expiresAt,
  String? localMediaPath,
}) {
  return MessageModel(
    id: 'message-1',
    senderId: 'sender',
    receiverId: 'receiver',
    text: '',
    timestamp: DateTime.utc(2026, 7, 1),
    type: 'image',
    mediaStoragePath:
        'privateChatMedia/sender/chat/message-1/upload.jpg',
    cloudExpiresAt: expiresAt,
    localMediaPath: localMediaPath,
  );
}

void main() {
  test('cloud delivery remains available strictly before expiry', () {
    final expiry = DateTime.utc(2026, 7, 8, 12);
    final message = _mediaMessage(expiresAt: expiry);

    expect(
      message.cloudDeliveryExpiredAt(expiry.subtract(const Duration(seconds: 1))),
      isFalse,
    );
  });

  test('cloud delivery expires at the exact seven-day boundary', () {
    final expiry = DateTime.utc(2026, 7, 8, 12);
    final message = _mediaMessage(expiresAt: expiry);

    expect(message.cloudDeliveryExpiredAt(expiry), isTrue);
    expect(
      message.cloudDeliveryExpiredAt(expiry.add(const Duration(seconds: 1))),
      isTrue,
    );
  });

  test('local media remains independently addressable after cloud expiry', () {
    final expiry = DateTime.utc(2026, 7, 8, 12);
    final message = _mediaMessage(
      expiresAt: expiry,
      localMediaPath: '/private/device/message-1.jpg',
    );

    expect(message.cloudDeliveryExpiredAt(expiry), isTrue);
    expect(message.hasLocalMedia, isTrue);
  });
}
