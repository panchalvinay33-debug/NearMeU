import 'package:cloud_firestore/cloud_firestore.dart';

class ChatClearPolicy {
  const ChatClearPolicy._();

  static DateTime? clearedAtForUser(
    Map<String, dynamic> chatData,
    String userId,
  ) {
    final rawStates = chatData['clearStates'];
    if (rawStates is! Map) return null;
    final rawState = rawStates[userId];
    if (rawState is! Map) return null;
    final value = rawState['clearedAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  static bool isVisibleAfterClear({
    required DateTime messageTimestamp,
    DateTime? clearedAt,
  }) {
    return clearedAt == null || messageTimestamp.isAfter(clearedAt);
  }

  static bool shouldShowChatPreview({
    required DateTime? lastMessageTime,
    DateTime? clearedAt,
  }) {
    if (clearedAt == null) return true;
    return lastMessageTime != null && lastMessageTime.isAfter(clearedAt);
  }
}
