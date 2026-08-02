class NotificationDestination {
  const NotificationDestination._({required this.type, this.value});

  const NotificationDestination.privateChat(String chatId)
    : this._(type: NotificationRoute.privateChatType, value: chatId);

  const NotificationDestination.audioCall(String callId)
    : this._(type: NotificationRoute.audioCallType, value: callId);

  const NotificationDestination.supportAnnouncements()
    : this._(type: NotificationRoute.supportAnnouncementType);

  final String type;
  final String? value;

  bool get isPrivateChat => type == NotificationRoute.privateChatType;
  bool get isAudioCall => type == NotificationRoute.audioCallType;
  bool get isSupportAnnouncement =>
      type == NotificationRoute.supportAnnouncementType;

  String get payload {
    if (isPrivateChat) return 'chat:$value';
    if (isAudioCall) return 'call:$value';
    return 'support:announcements';
  }
}

class NotificationRoute {
  const NotificationRoute._();

  static const String privateChatType = 'private_chat';
  static const String audioCallType = 'audio_call';
  static const String supportAnnouncementType = 'support_announcement';
  static const int maximumChatIdLength = 256;
  static const int maximumCallIdLength = 64;

  static NotificationDestination? fromData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == supportAnnouncementType) {
      return const NotificationDestination.supportAnnouncements();
    }
    if (type == audioCallType) {
      final callId = callIdFromData(data);
      return callId == null ? null : NotificationDestination.audioCall(callId);
    }
    final chatId = chatIdFromData(data);
    return chatId == null ? null : NotificationDestination.privateChat(chatId);
  }

  static NotificationDestination? fromPayload(String? value) {
    if (value == null) return null;
    final payload = value.trim();
    if (payload == 'support:announcements') {
      return const NotificationDestination.supportAnnouncements();
    }
    if (payload.startsWith('call:')) {
      final callId = normalizedCallId(payload.substring(5));
      return callId == null ? null : NotificationDestination.audioCall(callId);
    }
    if (!payload.startsWith('chat:')) return null;
    final chatId = normalizedChatId(payload.substring(5));
    return chatId == null ? null : NotificationDestination.privateChat(chatId);
  }

  static String? chatIdFromData(Map<String, dynamic> data) {
    if (data['type'] != privateChatType) return null;
    final value = data['chatId'];
    if (value is! String) return null;
    return normalizedChatId(value);
  }

  static String? callIdFromData(Map<String, dynamic> data) {
    if (data['type'] != audioCallType) return null;
    final value = data['callId'];
    if (value is! String) return null;
    return normalizedCallId(value);
  }

  static String? normalizedChatId(String? value) {
    if (value == null) return null;
    final chatId = value.trim();
    if (chatId.isEmpty || chatId.length > maximumChatIdLength) return null;
    return chatId;
  }

  static String? normalizedCallId(String? value) {
    if (value == null) return null;
    final callId = value.trim();
    if (callId.length < 20 || callId.length > maximumCallIdLength) return null;
    final valid = RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(callId);
    return valid ? callId : null;
  }

  static String? otherParticipant({
    required String currentUid,
    required dynamic participants,
  }) {
    if (currentUid.isEmpty ||
        participants is! List ||
        participants.length != 2) {
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
