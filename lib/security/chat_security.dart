class ChatSecurityException implements Exception {
  const ChatSecurityException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChatSecurity {
  static const int maxMessageLength = 1000;
  static const Duration minimumMessageInterval = Duration(seconds: 1);

  final Map<String, DateTime> _lastMessageSentAtByUser = <String, DateTime>{};

  String chatIdFor(String user1, String user2) {
    final participants = _validateParticipants(user1, user2);
    participants.sort();
    return participants.join('_');
  }

  String validateOutgoingMessage({
    required String senderId,
    required String receiverId,
    required String text,
    DateTime? now,
  }) {
    _validateParticipants(senderId, receiverId);

    final normalizedText = text.trim();

    if (normalizedText.isEmpty) {
      throw const ChatSecurityException('Message cannot be empty.');
    }

    if (normalizedText.length > maxMessageLength) {
      throw const ChatSecurityException(
        'Message cannot be longer than $maxMessageLength characters.',
      );
    }

    final sentAt = now ?? DateTime.now();
    final lastSentAt = _lastMessageSentAtByUser[senderId];

    if (lastSentAt != null &&
        sentAt.difference(lastSentAt) < minimumMessageInterval) {
      throw const ChatSecurityException(
        'Please wait before sending another message.',
      );
    }

    return normalizedText;
  }

  void recordMessageSent(String senderId, {DateTime? sentAt}) {
    _lastMessageSentAtByUser[senderId] = sentAt ?? DateTime.now();
  }

  List<String> _validateParticipants(String user1, String user2) {
    final firstUserId = user1.trim();
    final secondUserId = user2.trim();

    if (firstUserId.isEmpty || secondUserId.isEmpty) {
      throw const ChatSecurityException('Chat participants are required.');
    }

    if (firstUserId == secondUserId) {
      throw const ChatSecurityException('You cannot chat with yourself.');
    }

    return <String>[firstUserId, secondUserId];
  }
}
