class ChatPreviewModel {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String messageType;
  final bool isUnsent;
  final String? lastMessageSenderId;
  final bool? lastMessageSeen;
  final int unreadCount;
  final bool? isOtherUserOnline;

  ChatPreviewModel({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.messageType = 'text',
    this.isUnsent = false,
    this.lastMessageSenderId,
    this.lastMessageSeen,
    this.unreadCount = 0,
    this.isOtherUserOnline,
  });

  String get previewText {
    if (isUnsent) return 'This message was unsent';
    if (messageType == 'image') return 'Photo';
    if (messageType != 'text') return 'Attachment';
    final normalized = lastMessage.trim();
    if (normalized.isEmpty) return 'Start a conversation';
    return normalized;
  }
}
