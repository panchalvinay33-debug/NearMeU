class ChatPreviewModel {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String messageType;
  final bool isUnsent;
  final String? lastMessageSenderId;
  final bool? lastMessageSeen;
  final int unreadCount;
  final bool? isOtherUserOnline;

  const ChatPreviewModel({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.otherUserPhotoUrl,
    this.messageType = 'text',
    this.isUnsent = false,
    this.lastMessageSenderId,
    this.lastMessageSeen,
    this.unreadCount = 0,
    this.isOtherUserOnline,
  });

  factory ChatPreviewModel.fromMap(Map<String, dynamic> data) {
    final timeMillis = data['lastMessageTimeMillis'];
    return ChatPreviewModel(
      chatId: data['chatId'] is String ? data['chatId'] as String : '',
      otherUserId: data['otherUserId'] is String
          ? data['otherUserId'] as String
          : '',
      otherUserName: data['otherUserName'] is String
          ? data['otherUserName'] as String
          : 'NearMeU user',
      otherUserPhotoUrl: data['otherUserPhotoUrl'] is String
          ? data['otherUserPhotoUrl'] as String
          : null,
      lastMessage: data['lastMessage'] is String
          ? data['lastMessage'] as String
          : '',
      lastMessageTime: timeMillis is num
          ? DateTime.fromMillisecondsSinceEpoch(timeMillis.toInt())
          : null,
      messageType: data['messageType'] is String
          ? data['messageType'] as String
          : 'text',
      isUnsent: data['isUnsent'] == true,
      lastMessageSenderId: data['lastMessageSenderId'] is String
          ? data['lastMessageSenderId'] as String
          : null,
      lastMessageSeen: data['lastMessageSeen'] is bool
          ? data['lastMessageSeen'] as bool
          : null,
      unreadCount: data['unreadCount'] is num
          ? (data['unreadCount'] as num).toInt()
          : 0,
      isOtherUserOnline: data['isOtherUserOnline'] is bool
          ? data['isOtherUserOnline'] as bool
          : null,
    );
  }

  ChatPreviewModel copyWith({
    String? chatId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhotoUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? messageType,
    bool? isUnsent,
    String? lastMessageSenderId,
    bool? lastMessageSeen,
    int? unreadCount,
    bool? isOtherUserOnline,
  }) {
    return ChatPreviewModel(
      chatId: chatId ?? this.chatId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      messageType: messageType ?? this.messageType,
      isUnsent: isUnsent ?? this.isUnsent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSeen: lastMessageSeen ?? this.lastMessageSeen,
      unreadCount: unreadCount ?? this.unreadCount,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chatId': chatId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhotoUrl': otherUserPhotoUrl,
      'lastMessage': lastMessage,
      'lastMessageTimeMillis': lastMessageTime?.millisecondsSinceEpoch,
      'messageType': messageType,
      'isUnsent': isUnsent,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSeen': lastMessageSeen,
      'unreadCount': unreadCount,
      'isOtherUserOnline': isOtherUserOnline,
    };
  }

  String get previewText {
    if (isUnsent) return 'This message was unsent';
    if (messageType == 'image') return 'Photo';
    if (messageType == 'video') return 'Video';
    if (messageType != 'text') return 'Attachment';
    final normalized = lastMessage.trim();
    if (normalized.isEmpty) return 'Start a conversation';
    return normalized;
  }
}
