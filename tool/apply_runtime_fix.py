# One-time verified runtime patch trigger.
from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected exactly one match, found {count}")
    file.write_text(text.replace(old, new, 1), encoding="utf-8")


replace_once(
    "lib/screens/chats_screen.dart",
    """          otherUserId: chat.otherUserId,
          otherUserName: chat.otherUserName,
""",
    """          otherUserId: chat.otherUserId,
          otherUserName: chat.otherUserName,
          initialPhotoUrl: chat.otherUserPhotoUrl,
""",
)

replace_once(
    "lib/screens/chats_screen.dart",
    """    final sentByCurrentUser = chat.lastMessageSenderId == currentUserId;
    return Material(
""",
    """    final sentByCurrentUser = chat.lastMessageSenderId == currentUserId;
    final photoUrl = chat.otherUserPhotoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    return Material(
""",
)

replace_once(
    "lib/screens/chats_screen.dart",
    """                  CircleAvatar(
                    radius: 30,
                    backgroundColor: avatarColor,
                    child: Text(
                      chat.otherUserName.isEmpty
                          ? '?'
                          : chat.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
""",
    """                  CircleAvatar(
                    radius: 30,
                    backgroundColor: avatarColor,
                    foregroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                    onForegroundImageError: hasPhoto ? (_, __) {} : null,
                    child: Text(
                      chat.otherUserName.isEmpty
                          ? '?'
                          : chat.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
""",
)

replace_once(
    "lib/screens/chat_screen.dart",
    """  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });
""",
    """  final String otherUserId;
  final String otherUserName;
  final String? initialPhotoUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.initialPhotoUrl,
  });
""",
)

replace_once(
    "lib/screens/chat_screen.dart",
    """              final otherUser = snapshot.data;
              final isOnline =
""",
    """              final otherUser = snapshot.data;
              final livePhotoUrl = otherUser?.photoUrl?.trim();
              final isOnline =
""",
)

replace_once(
    "lib/screens/chat_screen.dart",
    """                isOnline: isOnline,
                onBack: () => Navigator.pop(context),
""",
    """                isOnline: isOnline,
                photoUrl: livePhotoUrl != null && livePhotoUrl.isNotEmpty
                    ? livePhotoUrl
                    : widget.initialPhotoUrl,
                onBack: () => Navigator.pop(context),
""",
)

replace_once(
    "lib/screens/settings_screen.dart",
    """    final lookingFor = user?.lookingFor.trim().isNotEmpty == true
        ? user!.lookingFor
        : 'Not set';

    return Container(
""",
    """    final lookingFor = user?.lookingFor.trim().isNotEmpty == true
        ? user!.lookingFor
        : 'Not set';
    final photoUrl = user?.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
""",
)

replace_once(
    "lib/screens/settings_screen.dart",
    """          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            child: Text(
""",
    """          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            foregroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            onForegroundImageError: hasPhoto ? (_, __) {} : null,
            child: Text(
""",
)

replace_once(
    "lib/services/private_media_service.dart",
    """      await _localChatStore.markMediaDownloaded(
        ownerUid: ownerUid,
        chatId: chatId,
        messageId: message.id,
        localMediaPath: destination.path,
        localThumbnailPath: localThumbnailPath,
      );
      await _acknowledgeDownload(
""",
    """      final downloadedMessage = message.withLocalMedia(
        localMediaPath: destination.path,
        localThumbnailPath: localThumbnailPath,
      );
      await _localChatStore.upsertMessages(
        ownerUid: ownerUid,
        records: <LocalStoredMessage>[
          LocalStoredMessage(
            chatId: chatId,
            message: downloadedMessage,
            localMediaPath: destination.path,
            localThumbnailPath: localThumbnailPath,
            cloudExpiresAt: message.cloudExpiresAt,
            downloadComplete: true,
            cloudMediaDeleted: message.cloudMediaDeletedAt != null,
            pendingUpload: false,
          ),
        ],
      );
      await _acknowledgeDownload(
""",
)

replace_once(
    "lib/widgets/chat/private_media_content.dart",
    """    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.localMediaPath != widget.message.localMediaPath) {
      _localPath = widget.message.localMediaPath;
      _thumbnailPath = widget.message.localThumbnailPath;
      _discardMissingLocalFiles();
    }
""",
    """    if (oldWidget.message.id != widget.message.id) {
      _localPath = widget.message.localMediaPath;
      _thumbnailPath = widget.message.localThumbnailPath;
      _discardMissingLocalFiles();
      return;
    }

    final nextLocalPath = widget.message.localMediaPath;
    if (nextLocalPath != null && nextLocalPath.trim().isNotEmpty) {
      _localPath = nextLocalPath;
    }
    final nextThumbnailPath = widget.message.localThumbnailPath;
    if (nextThumbnailPath != null && nextThumbnailPath.trim().isNotEmpty) {
      _thumbnailPath = nextThumbnailPath;
    }
    _discardMissingLocalFiles();
""",
)

replace_once(
    "lib/widgets/chat/message_bubble.dart",
    """                      PrivateMediaContent(message: message),
""",
    """                      PrivateMediaContent(
                        key: ValueKey(message.id),
                        message: message,
                      ),
""",
)

print("NearMeU runtime patch applied successfully.")
