import 'message_model.dart';

class LocalStoredMessage {
  const LocalStoredMessage({
    required this.chatId,
    required this.message,
    this.localMediaPath,
    this.localThumbnailPath,
    this.cloudExpiresAt,
    this.downloadComplete = false,
    this.cloudMediaDeleted = false,
    this.pendingUpload = false,
  });

  final String chatId;
  final MessageModel message;
  final String? localMediaPath;
  final String? localThumbnailPath;
  final DateTime? cloudExpiresAt;
  final bool downloadComplete;
  final bool cloudMediaDeleted;
  final bool pendingUpload;

  LocalStoredMessage copyWith({
    MessageModel? message,
    String? localMediaPath,
    String? localThumbnailPath,
    DateTime? cloudExpiresAt,
    bool? downloadComplete,
    bool? cloudMediaDeleted,
    bool? pendingUpload,
    bool clearLocalMediaPath = false,
    bool clearLocalThumbnailPath = false,
  }) {
    return LocalStoredMessage(
      chatId: chatId,
      message: message ?? this.message,
      localMediaPath: clearLocalMediaPath
          ? null
          : (localMediaPath ?? this.localMediaPath),
      localThumbnailPath: clearLocalThumbnailPath
          ? null
          : (localThumbnailPath ?? this.localThumbnailPath),
      cloudExpiresAt: cloudExpiresAt ?? this.cloudExpiresAt,
      downloadComplete: downloadComplete ?? this.downloadComplete,
      cloudMediaDeleted: cloudMediaDeleted ?? this.cloudMediaDeleted,
      pendingUpload: pendingUpload ?? this.pendingUpload,
    );
  }
}
