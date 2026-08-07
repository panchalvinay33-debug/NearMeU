import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/app_user.dart';
import '../models/message_model.dart';
import '../services/audio_call_service.dart';
import '../services/chat_service.dart';
import '../services/local_chat_store.dart';
import '../services/private_media_service.dart';
import '../services/user_service.dart';
import '../services/voice_message_service.dart';
import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/composer.dart';
import '../widgets/chat/date_chip.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/reply_preview.dart';
import 'audio_call_history_screen.dart';
import 'audio_call_screen.dart';
import 'user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.initialPhotoUrl,
  });

  final String otherUserId;
  final String otherUserName;
  final String? initialPhotoUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final LocalChatStore _localChatStore = LocalChatStore();
  late final ChatService _chatService = ChatService(
    localChatStore: _localChatStore,
  );
  late final PrivateMediaService _mediaService = PrivateMediaService(
    localChatStore: _localChatStore,
  );
  late final VoiceMessageService _voiceService = VoiceMessageService(
    localChatStore: _localChatStore,
  );
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );
  final AudioCallService _audioCalls = AudioCallService();
  final UserService _userService = UserService();
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  MessageModel? _replyingTo;
  bool _showEmojiPicker = false;
  bool _isBlocked = false;
  bool _isSending = false;
  bool _isSendingMedia = false;
  bool _checkingBlock = true;
  bool _isRecordingVoice = false;
  bool _isAcknowledgingRead = false;
  bool _isClearingChat = false;
  bool _isStartingCall = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _readAcknowledgementTimer;
  Timer? _recordingTimer;
  String? _recordingPath;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
    _readAcknowledgementTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_markChatOpened()),
    );
  }

  Future<void> _initialize() async {
    await _checkBlockStatus();
    await _markChatOpened();
    final user = currentUser;
    if (user != null && !_isBlocked) {
      try {
        await _mediaService.recoverPendingUploads(
          ownerUid: user.uid,
          otherUserId: widget.otherUserId,
        );
      } catch (_) {
        // The outbox is retried the next time this chat opens.
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _isRecordingVoice) {
      unawaited(_cancelVoiceRecording());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readAcknowledgementTimer?.cancel();
    _recordingTimer?.cancel();
    if (_isRecordingVoice) unawaited(_recorder.cancel());
    unawaited(_recorder.dispose());
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
      if (mounted) setState(() => _checkingBlock = false);
    }
  }

  Future<void> _markChatOpened() async {
    final user = currentUser;
    if (user == null || _isBlocked || _isAcknowledgingRead) return;
    _isAcknowledgingRead = true;
    try {
      await _functions.httpsCallable('markPrivateChatRead').call<void>(
        <String, dynamic>{'otherUserId': widget.otherUserId},
      );
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found' || error.code == 'unimplemented') {
        try {
          await _chatService.markMessagesAsSeen(
            currentUserId: user.uid,
            otherUserId: widget.otherUserId,
          );
        } catch (_) {}
      }
    } catch (_) {
      // The periodic acknowledgement retries temporary failures.
    } finally {
      _isAcknowledgingRead = false;
    }
  }

  Future<void> _startAudioCall() async {
    if (_checkingBlock ||
        _isBlocked ||
        _isStartingCall ||
        _isSending ||
        _isSendingMedia ||
        _isClearingChat) {
      return;
    }
    if (_isRecordingVoice) await _cancelVoiceRecording();
    if (!mounted) return;
    _messageFocusNode.unfocus();
    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
    setState(() => _isStartingCall = true);
    try {
      await _checkBlockStatus();
      if (!mounted || _isBlocked) return;
      final session = await _audioCalls.startCall(widget.otherUserId);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AudioCallScreen(
            initialSession: session,
            incoming: false,
          ),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = error.message?.trim();
      _showError(
        message == null || message.isEmpty
            ? 'Could not start the audio call.'
            : message,
      );
      await _checkBlockStatus();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isStartingCall = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final user = currentUser;
    if (text.isEmpty || user == null) return;
    if (_isBlocked ||
        _isSending ||
        _isSendingMedia ||
        _isRecordingVoice ||
        _isClearingChat) {
      return;
    }

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
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showAttachmentSheet() async {
    if (_isBlocked ||
        _isSending ||
        _isSendingMedia ||
        _isRecordingVoice ||
        _isClearingChat) {
      return;
    }
    _messageFocusNode.unfocus();
    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);

    final selection = await showModalBottomSheet<_AttachmentSelection>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
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
                sheetContext,
                icon: Icons.photo_library_rounded,
                title: 'Photo from gallery',
                subtitle: 'Compressed before upload',
                selection: const _AttachmentSelection(
                  type: _AttachmentType.image,
                  source: ImageSource.gallery,
                ),
              ),
              _attachmentTile(
                sheetContext,
                icon: Icons.camera_alt_rounded,
                title: 'Take a photo',
                subtitle: 'Saved privately in this chat',
                selection: const _AttachmentSelection(
                  type: _AttachmentType.image,
                  source: ImageSource.camera,
                ),
              ),
              _attachmentTile(
                sheetContext,
                icon: Icons.video_library_rounded,
                title: 'Video from gallery',
                subtitle: 'Maximum 2 minutes, compressed MP4',
                selection: const _AttachmentSelection(
                  type: _AttachmentType.video,
                  source: ImageSource.gallery,
                ),
              ),
              _attachmentTile(
                sheetContext,
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
      ),
    );
    if (selection != null && mounted) await _prepareAndSendMedia(selection);
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
    if (user == null || _isBlocked || _isSendingMedia || _isClearingChat) {
      return;
    }
    setState(() => _isSendingMedia = true);
    try {
      final PreparedPrivateMedia? media =
          selection.type == _AttachmentType.image
          ? await _mediaService.pickImage(source: selection.source)
          : await _mediaService.pickVideo(source: selection.source);
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
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecordingVoice) {
      await _stopAndSendVoice();
    } else {
      await _startVoiceRecording();
    }
  }

  Future<void> _startVoiceRecording() async {
    if (_isBlocked ||
        _isSending ||
        _isSendingMedia ||
        _isRecordingVoice ||
        _isClearingChat) {
      return;
    }
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (mounted) {
        _showError(
          const VoiceMessageException(
            'Microphone permission is required for voice messages.',
          ),
        );
      }
      return;
    }

    _messageFocusNode.unfocus();
    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
    final temporary = await getTemporaryDirectory();
    final path = p.join(
      temporary.path,
      'nearmeu_voice_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _isRecordingVoice = true;
        _recordingDuration = Duration.zero;
        _recordingPath = path;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecordingVoice) return;
        final next = _recordingDuration + const Duration(seconds: 1);
        setState(() => _recordingDuration = next);
        if (next >= VoiceMessageService.maximumVoiceDuration) {
          unawaited(_stopAndSendVoice());
        }
      });
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _stopAndSendVoice() async {
    if (!_isRecordingVoice || _isSendingMedia) return;
    _recordingTimer?.cancel();
    final measuredDuration = _recordingDuration;
    final expectedPath = _recordingPath;
    setState(() {
      _isRecordingVoice = false;
      _isSendingMedia = true;
    });

    try {
      final stoppedPath = await _recorder.stop();
      final path = stoppedPath ?? expectedPath;
      final user = currentUser;
      if (path == null || user == null) {
        throw const VoiceMessageException('Could not finish voice recording.');
      }
      await _voiceService.sendRecordedVoice(
        senderId: user.uid,
        receiverId: widget.otherUserId,
        sourceFile: File(path),
        durationMs: measuredDuration.inMilliseconds,
        replyTo: _replyingTo,
      );
      if (mounted) {
        setState(() {
          _replyingTo = null;
          _recordingDuration = Duration.zero;
          _recordingPath = null;
        });
      }
      _scrollToBottom();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
          _recordingDuration = Duration.zero;
          _recordingPath = null;
        });
      }
    }
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_isRecordingVoice) return;
    _recordingTimer?.cancel();
    try {
      await _recorder.cancel();
    } catch (_) {}
    final path = _recordingPath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _recordingDuration = Duration.zero;
        _recordingPath = null;
      });
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
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  String _replyPreviewText(MessageModel message) {
    if (message.isUnsent) return 'This message was unsent';
    if (message.isImage) return 'Photo';
    if (message.isVideo) return 'Video';
    if (message.isVoice) return 'Voice message';
    final text = message.text.trim();
    if (text.isEmpty) return 'Message';
    return text.length > 60 ? '${text.substring(0, 60)}...' : text;
  }

  String _replySenderLabel(MessageModel message) {
    return currentUser != null && message.senderId == currentUser!.uid
        ? 'You'
        : widget.otherUserName;
  }

  void _toggleEmojiPicker() {
    if (_isBlocked || _isSendingMedia || _isRecordingVoice || _isClearingChat) {
      return;
    }
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
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message copied')));
    }
  }

  Future<void> _deleteForMe(MessageModel message) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _chatService.deleteMessageForMe(
        currentUserId: user.uid,
        otherUserId: widget.otherUserId,
        message: message,
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _unsend(MessageModel message) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _chatService.unsendMessage(
        currentUserId: user.uid,
        otherUserId: widget.otherUserId,
        message: message,
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _showMessageOptions(MessageModel message) async {
    final user = currentUser;
    if (user == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (!_isBlocked)
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Colors.white),
                title: const Text(
                  'Reply',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _replyingTo = message);
                },
              ),
            if (!message.isUnsent && message.text.trim().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white),
                title: const Text(
                  'Copy',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(_copyMessage(message));
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.white),
              title: const Text(
                'Delete for me',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(_deleteForMe(message));
              },
            ),
            if (message.canUnsend(user.uid))
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete for everyone',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(_unsend(message));
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatLastSeen(DateTime? value) {
    if (value == null) return 'Offline';
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 2) return 'Last seen just now';
    if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hr ago';
    }
    return 'Last seen ${value.day}/${value.month}/${value.year}';
  }

  String _dateLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
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
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  bool _showDateHeader(List<MessageModel> messages, int index) {
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
    if (!_showEmojiPicker || _isBlocked || _isRecordingVoice) {
      return const SizedBox.shrink();
    }
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

  Widget _buildComposer() {
    if (_isBlocked) {
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
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: [
        ChatComposer(
          controller: _messageController,
          focusNode: _messageFocusNode,
          showEmojiPicker: _showEmojiPicker,
          isSendingMedia: _isSendingMedia || _isClearingChat,
          isRecordingVoice: _isRecordingVoice,
          recordingDuration: _recordingDuration,
          onEmojiTap: _toggleEmojiPicker,
          onAttachment:
              _isSending || _isSendingMedia || _isRecordingVoice || _isClearingChat
              ? null
              : _showAttachmentSheet,
          onVoiceTap: _isSending || _isSendingMedia || _isClearingChat
              ? null
              : _toggleVoiceRecording,
          onCancelVoice: _isRecordingVoice ? _cancelVoiceRecording : null,
          onSend:
              _isSending || _isSendingMedia || _isRecordingVoice || _isClearingChat
              ? null
              : _sendMessage,
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
    var reason = 'Spam';
    final description = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Report User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: reason,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                items:
                    const <String>[
                          'Spam',
                          'Fake Profile',
                          'Harassment',
                          'Hate Speech',
                          'Scam/Fraud',
                          'Inappropriate Content',
                          'Other',
                        ]
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => reason = value);
                },
              ),
              if (reason == 'Other')
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe the problem',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _userService.reportUser(
                    reporterId: user.uid,
                    reportedUserId: widget.otherUserId,
                    reason: reason,
                    description: description.text.trim(),
                  );
                } catch (error) {
                  if (mounted) _showError(error);
                }
              },
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
    description.dispose();
  }

  Future<void> _openOtherUserProfile() async {
    try {
      final profile = await _userService.getUser(widget.otherUserId);
      if (!mounted) return;
      if (profile == null) {
        _showError('Profile is not available right now.');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserProfileScreen(user: profile)),
      );
      await _checkBlockStatus();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _clearChat() async {
    final user = currentUser;
    if (user == null || _isClearingChat) return;
    if (_isSending || _isSendingMedia || _isRecordingVoice) {
      _showError('Finish the current send or recording before clearing chat.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear Chat?'),
        content: const Text(
          'This permanently removes this conversation, downloaded media, voice notes and local chat history for you. The other person keeps their copy. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear Chat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isClearingChat = true;
      _replyingTo = null;
      _showEmojiPicker = false;
    });
    try {
      await _chatService.clearChat(
        currentUserId: user.uid,
        otherUserId: widget.otherUserId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _isClearingChat = false);
        _showError(error);
      }
    }
  }

  Future<void> _showChatMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.history_rounded, color: Colors.white),
              title: const Text(
                'Call history',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AudioCallHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Clear Chat',
                style: TextStyle(color: Colors.redAccent),
              ),
              subtitle: const Text(
                'Permanently remove this chat for you',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(_clearChat());
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: Colors.redAccent),
              title: const Text(
                'Report User',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(_showReportDialog());
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text(
                'View Profile',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(_openOtherUserProfile());
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text(
                'Block User',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
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
      ),
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
              final callingDisabled =
                  _checkingBlock ||
                  _isBlocked ||
                  _isStartingCall ||
                  _isClearingChat;
              return ChatAppBar(
                userName: widget.otherUserName,
                lastSeen: isOnline
                    ? 'Online'
                    : _formatLastSeen(otherUser?.lastSeen),
                isOnline: isOnline,
                photoUrl: livePhotoUrl != null && livePhotoUrl.isNotEmpty
                    ? livePhotoUrl
                    : widget.initialPhotoUrl,
                onBack: () async {
                  if (_isRecordingVoice) await _cancelVoiceRecording();
                  if (context.mounted) Navigator.pop(context);
                },
                onAudioCall: callingDisabled ? null : _startAudioCall,
                onMenu: _isClearingChat ? null : _showChatMenu,
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
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                          );
                        }
                        if (snapshot.hasError && !snapshot.hasData) {
                          return Center(
                            child: Text(
                              'Could not load messages.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        final messages =
                            snapshot.data ?? const <MessageModel>[];
                        if (messages.any(
                          (message) =>
                              message.receiverId == user.uid && !message.isSeen,
                        )) {
                          unawaited(_markChatOpened());
                        }
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet. Say hello!',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == user.uid;
                            return Column(
                              children: [
                                if (_showDateHeader(messages, index))
                                  DateChip(text: _dateLabel(message.timestamp)),
                                MessageBubble(
                                  message: message,
                                  isMe: isMe,
                                  repliedToMe:
                                      message.replyToSenderId == user.uid,
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
                  _buildComposer(),
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
