class NotificationRoute {
  const NotificationRoute._();

  static const int maximumChatIdLength = 256;

  static String? chatIdFromData(Map<String, dynamic> data) {
    if (data['type'] != 'chat') return null;
    final value = data['chatId'];
    if (value is! String) return null;

    final chatId = value.trim();
    if (chatId.isEmpty || chatId.length > maximumChatIdLength) return null;
    return chatId;
  }

  static String? normalizedChatId(String? value) {
    if (value == null) return null;
    final chatId = value.trim();
    if (chatId.isEmpty || chatId.length > maximumChatIdLength) return null;
    return chatId;
  }

  static String? otherParticipant({
    required String currentUid,
    required dynamic participants,
  }) {
    if (currentUid.isEmpty || participants is! List || participants.length != 2) {
      return null;
    }

    final first = participants[0];
    final second = participants[1];
    if (first is! String || second is! String) return null;
    if (first.isEmpty || second.isEmpty || first == second) return null;
    if (currentUid == first) return second;
    if (currentUid == second) return first;
    return null;
  }
}
