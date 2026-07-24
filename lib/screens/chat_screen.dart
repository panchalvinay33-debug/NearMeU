import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/private_media_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/composer.dart';
import '../widgets/chat/date_chip.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/reply_preview.dart';
import 'user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? initialPhotoUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.initialPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final PrivateMediaService _mediaService = PrivateMediaService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  MessageModel? _replyingTo;
  bool _showEmojiPicker = false;
  bool _isBlocked = false;
  bool _isSending = false;
  bool _isSendingMedia = false;
  bool _checkingBlock = true;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initChatScreen();
  }

  Future<void> _initChatScreen() async {
    await _checkBlockStatus();
    await _markChatOpened();

    final user = currentUser;
    if (user != null && !_isBlocked) {
      await _mediaService.recoverPendingUploads(
        ownerUid: user.uid,
        otherUserId: widget.otherUserId,
      );
    }
  }

  Future<void> _checkBlockStatus() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final blocked = await _userService.isBlockedEitherWay(
        currentUserId: user.uid,
        otherUserId: widget.otherUserId,
      );
      if (!mounted) return;
      setState(() {
        _isBlocked = blocked;
        _checkingBlock = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingBlock = false);
    }
  }

  Future<void> _markChatOpened() async {
    final user = currentUser;
    if (user == null || _isBlocked) return;
    await _userService.updateLastSeen(user.uid);
    await _chatService.markMessagesAsSeen(
      currentUserId: user.uid,
      otherUserId: widget.otherUserId,
    );
  }

  @override
  void dispose() {
    final user = currentUser;
    if (user != null) _userService.updateLastSeen(user.uid);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final user = currentUser;
    if (text.isEmpty || user == null) return;
    if (_isBlocked || _isSending || _isSendingMedia) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(
        senderId: user.uid,
        receiverId: widget.otherUserId,
        text: text,
        replyTo: _replyingTo,
      );
      _messageController.clear();
      if (mounted) setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (error) {
      await _checkBlockStatus();
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showAttachmentSheet() async {
    if (_isBlocked || _isSending || _isSendingMedia) return;
    _messageFocusNode.unfocus();
    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);

    final selection = await showModalBottomSheet<_AttachmentSelection>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: Text(
                    'Send private media',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _attachmentTile(
                  context,
                  icon: Icons.photo_library_rounded,
                  title: 'Photo from gallery',
                  subtitle: 'Compressed before upload',
                  selection: const _AttachmentSelection(
                    type: _AttachmentType.image,
                    source: ImageSource.gallery,
                  ),
                ),
                _attachmentTile(
                  context,
                  icon: Icons.camera_alt_rounded,
                  title: 'Take a photo',
                  subtitle: 'Saved privately in this chat',
                  selection: const _AttachmentSelection(
                    type: _AttachmentType.image,
                    source: ImageSource.camera,
                  ),
                ),
                _attachmentTile(
                  context,
                  icon: Icons.video_library_rounded,
                  title: 'Video from gallery',
                  subtitle: 'Maximum 2 minutes • compressed MP4',
                  selection: const _AttachmentSelection(
                    type: _AttachmentType.video,
                    source: ImageSource.gallery,
                  ),
                ),
                _attachmentTile(
                  context,
                  icon: Icons.videocam_rounded,
                  title: 'Record a video',
                  subtitle: 'Maximum 2 minutes',
                  selection: const _AttachmentSelection(
                    type: _AttachmentType.video,
                    source: ImageSource.camera,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selection == null || !mounted) return;
    await _prepareAndSendMedia(selection);
  }

  Widget _attachmentTile(
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String subtitle,
    required _AttachmentSelection selection,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: .16),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: () => Navigator.pop(sheetContext, selection),
    );
  }

  Future<void> _prepareAndSendMedia(_AttachmentSelection selection) async {
    final user = currentUser;
    if (user == null || _isBlocked || _isSendingMedia) return;
    setState(() => _isSendingMedia = true);

    try {
      final PreparedPrivateMedia? media;
      if (selection.type == _AttachmentType.image) {
        media = await _mediaService.pickImage(source: selection.source);
      } else {
        media = await _mediaService.pickVideo(source: selection.source);
      }
      if (media == null) return;

      await _mediaService.sendPreparedMedia(
        senderId: user.uid,
        receiverId: widget.otherUserId,
        media: media,
        caption: _messageController.text.trim(),
        replyTo: _replyingTo,
      );
      _messageController.clear();
      if (mounted) setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (error) {
      await _checkBlockStatus();
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _replyPreviewText(MessageModel message) {
    if (message.isUnsent) return 'This message was unsent';
    if (message.isImage) return 'Photo';
    if (message.isVideo) return 'Video';
    final text = message.text.trim();
    if (text.isEmpty) return 'Message';
    return text.length > 60 ? '${text.substring(0, 60)}...' : text;
  }

  String _replySenderLabel(MessageModel message) {
    return currentUser != null && message.senderId == currentUser!.uid
        ? 'You'
        : widget.otherUserName;
  }

  void _startReply(MessageModel message) {
    if (_isBlocked) return;
    setState(() => _replyingTo = message);
  }

  void _toggleEmojiPicker() {
    if (_isBlocked || _isSendingMedia) return;
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _messageFocusNode.requestFocus();
    } else {
      _messageFocusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  Future<void> _copyMessage(MessageModel message) async {
    if (message.isUnsent || message.text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: message.text.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message copied')));
  }

  Future<void> _deleteForMe(MessageModel message) async {
    final user = currentUser;
    if (user == null) return;
    await _chatService.deleteMessageForMe(
      currentUserId: user.uid,
      otherUserId: widget.otherUserId,
      message: message,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message deleted for you')));
  }

  Future<void> _showMessageOptions(MessageModel message) async {
    final user = currentUser;
    if (user == null) return;
    final canUnsend = message.canUnsend(user.uid);
    final isMe = message.senderId == user.uid;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: [
                if (!_isBlocked)
                  ListTile(
                    leading: const Icon(
                      Icons.reply_rounded,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Reply',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _startReply(message);
                    },
                  ),
                if (!message.isUnsent && message.text.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.copy_rounded,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Copy',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _copyMessage(message);
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Delete for me',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteForMe(message);
                  },
                ),
                if (isMe && canUnsend)
                  ListTile(
                    leading: const Icon(
                      Icons.undo_rounded,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Unsend',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Remove for both users',
                      style: TextStyle(color: Colors.white54),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _chatService.unsendMessage(
                        currentUserId: user.uid,
                        otherUserId: widget.otherUserId,
                        message: message,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatLastSeen(DateTime? dateTime) {
    if (_isBlocked) return 'Unavailable';
    if (dateTime == null) return 'Last seen recently';
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'Last seen just now';
    if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hr ago';
    }
    return 'Last seen ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(messageDay).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  bool _shouldShowDateHeader(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].timestamp;
    final previous = messages[index - 1].timestamp;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget _buildReplyPreview() {
    final replyingTo = _replyingTo;
    if (replyingTo == null || _isBlocked) return const SizedBox.shrink();
    return ReplyPreview(
      replyingTo: replyingTo,
      senderName: _replySenderLabel(replyingTo),
      previewText: _replyPreviewText(replyingTo),
      onClose: () => setState(() => _replyingTo = null),
    );
  }

  Widget _buildEmojiPicker() {
    if (!_showEmojiPicker || _isBlocked) return const SizedBox.shrink();
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        textEditingController: _messageController,
        config: const Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28,
            columns: 8,
            backgroundColor: Color(0xff0B0B0B),
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: Color(0xff171717),
            iconColorSelected: AppColors.primary,
            iconColor: Colors.white54,
            indicatorColor: AppColors.primary,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: Color(0xff171717),
            buttonColor: AppColors.primary,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: Color(0xff171717),
            buttonIconColor: Colors.white,
            hintTextStyle: TextStyle(color: Colors.white54),
            inputTextStyle: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'You cannot send messages in this chat.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _buildComposer() {
    if (_isBlocked) return _buildBlockedBar();
    return Column(
      children: [
        ChatComposer(
          controller: _messageController,
          focusNode: _messageFocusNode,
          showEmojiPicker: _showEmojiPicker,
          isSendingMedia: _isSendingMedia,
          onEmojiTap: _toggleEmojiPicker,
          onAttachment: _isSending || _isSendingMedia
              ? null
              : _showAttachmentSheet,
          onSend: _isSending || _isSendingMedia ? null : _sendMessage,
          onTextFieldTap: () {
            if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
          },
          replyPreview: _replyingTo == null ? null : _buildReplyPreview(),
        ),
        _buildEmojiPicker(),
      ],
    );
  }

  Future<void> _showReportDialog() async {
    final user = currentUser;
    if (user == null) return;
    var selectedReason = 'Spam';
    final descriptionController = TextEditingController();
    const reasons = <String>[
      'Spam',
      'Fake Profile',
      'Harassment',
      'Hate Speech',
      'Scam/Fraud',
      'Inappropriate Content',
      'Other',
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Report User',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedReason,
                      dropdownColor: AppColors.surface,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      items: reasons
                          .map(
                            (reason) => DropdownMenuItem<String>(
                              value: reason,
                              child: Text(reason),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedReason = value);
                        }
                      },
                    ),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe the problem',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await _userService.reportUser(
                        reporterId: user.uid,
                        reportedUserId: widget.otherUserId,
                        reason: selectedReason,
                        description: descriptionController.text.trim(),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User reported successfully.'),
                        ),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      _showError(error);
                    }
                  },
                  child: const Text('Report'),
                ),
              ],
            );
          },
        );
      },
    );
    descriptionController.dispose();
  }

  Future<void> _openOtherUserProfile() async {
    try {
      final profile = await _userService.getUser(widget.otherUserId);
      if (!mounted) return;
      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile is not available right now.')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserProfileScreen(user: profile)),
      );
      await _checkBlockStatus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this profile.')),
      );
    }
  }

  Future<void> _showChatMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.flag_rounded, color: Colors.red),
                title: const Text(
                  'Report User',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text(
                  'View Profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _openOtherUserProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.white),
                title: const Text(
                  'Block User',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final user = currentUser;
                  if (user == null) return;
                  await _userService.blockUser(
                    currentUserId: user.uid,
                    targetUserId: widget.otherUserId,
                  );
                  await _checkBlockStatus();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'User not logged in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xff0B0B0B),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: StreamBuilder<AppUser?>(
            stream: _userService.streamUser(widget.otherUserId),
            builder: (context, snapshot) {
              final otherUser = snapshot.data;
              final livePhotoUrl = otherUser?.photoUrl?.trim();
              final isOnline =
                  !_isBlocked &&
                  otherUser != null &&
                  NearbyUserPresenter.isEffectivelyOnline(otherUser);
              return ChatAppBar(
                userName: widget.otherUserName,
                lastSeen: isOnline
                    ? 'Online'
                    : _formatLastSeen(otherUser?.lastSeen),
                isOnline: isOnline,
                photoUrl: livePhotoUrl != null && livePhotoUrl.isNotEmpty
                    ? livePhotoUrl
                    : widget.initialPhotoUrl,
                onBack: () => Navigator.pop(context),
                onMenu: _showChatMenu,
              );
            },
          ),
        ),
        body: _checkingBlock
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _chatService.getMessages(
                        user1: user.uid,
                        user2: widget.otherUserId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final messages = snapshot.data ?? <MessageModel>[];
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet 👋',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == user.uid;
                            final repliedToMe =
                                message.replyToSenderId == user.uid;
                            return Column(
                              children: [
                                if (_shouldShowDateHeader(messages, index))
                                  DateChip(
                                    text: _formatDateHeader(message.timestamp),
                                  ),
                                MessageBubble(
                                  message: message,
                                  isMe: isMe,
                                  repliedToMe: repliedToMe,
                                  otherUserName: widget.otherUserName,
                                  time: _formatMessageTime(message.timestamp),
                                  onLongPress: () =>
                                      _showMessageOptions(message),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(top: false, child: _buildComposer()),
                ],
              ),
      ),
    );
  }
}

enum _AttachmentType { image, video }

class _AttachmentSelection {
  const _AttachmentSelection({required this.type, required this.source});

  final _AttachmentType type;
  final ImageSource source;
}
