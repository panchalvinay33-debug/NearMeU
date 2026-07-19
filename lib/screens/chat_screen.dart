import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  MessageModel? _replyingTo;
  bool _showEmojiPicker = false;
  bool _isBlocked = false;
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
  }

  Future<void> _checkBlockStatus() async {
    if (currentUser == null) return;

    final blocked = await _userService.isBlockedEitherWay(
      currentUserId: currentUser!.uid,
      otherUserId: widget.otherUserId,
    );

    if (!mounted) return;
    setState(() {
      _isBlocked = blocked;
      _checkingBlock = false;
    });
  }

  Future<void> _markChatOpened() async {
  if (currentUser == null) return;

  print("==============");
  print("Current UID : ${currentUser!.uid}");
  print("Other UID   : ${widget.otherUserId}");
  print(
    "Chat ID     : ${_chatService.getChatId(currentUser!.uid, widget.otherUserId)}",
  );

  if (_isBlocked) return;

  await _userService.updateLastSeen(currentUser!.uid);

  await _chatService.markMessagesAsSeen(
    currentUserId: currentUser!.uid,
    otherUserId: widget.otherUserId,
  );
}

  @override
  void dispose() {
    if (currentUser != null) {
      _userService.updateLastSeen(currentUser!.uid);
    }
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;
    if (_isBlocked) return;

    try {
      await _chatService.sendMessage(
        senderId: currentUser!.uid,
        receiverId: widget.otherUserId,
        text: text,
        replyTo: _replyingTo,
      );

      _messageController.clear();

      if (mounted) {
        setState(() {
          _replyingTo = null;
        });
      }

      _scrollToBottom();
    } catch (_) {
      await _checkBlockStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot send messages in this chat.'),
        ),
      );
    }
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

    final text = message.text.trim();
    if (text.isEmpty) return 'Message';

    if (text.length > 60) {
      return '${text.substring(0, 60)}...';
    }

    return text;
  }

  String _replySenderLabel(MessageModel message) {
    if (currentUser != null && message.senderId == currentUser!.uid) {
      return 'You';
    }
    return widget.otherUserName;
  }

  void _startReply(MessageModel message) {
    if (_isBlocked) return;

    setState(() {
      _replyingTo = message;
    });
  }

  void _toggleEmojiPicker() {
    if (_isBlocked) return;

    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
      _messageFocusNode.requestFocus();
    } else {
      _messageFocusNode.unfocus();
      setState(() {
        _showEmojiPicker = true;
      });
    }
  }

  Future<void> _copyMessage(MessageModel message) async {
    if (message.isUnsent) return;
    if (message.text.trim().isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: message.text.trim()),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
      ),
    );
  }

  Future<void> _deleteForMe(MessageModel message) async {
    if (currentUser == null) return;

    await _chatService.deleteMessageForMe(
      currentUserId: currentUser!.uid,
      otherUserId: widget.otherUserId,
      message: message,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message deleted for you'),
      ),
    );
  }

  Future<void> _showMessageOptions(MessageModel message) async {
    if (currentUser == null) return;

    final canUnsend = message.canUnsend(currentUser!.uid);
    final isMe = message.senderId == currentUser!.uid;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff171717),
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
                      Icons.reply,
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
                      Icons.copy,
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
                    Icons.delete_outline,
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
                      Icons.undo,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Unsend',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Remove this message for both users',
                      style: TextStyle(color: Colors.white54),
                    ),
                    onTap: () async {
                      Navigator.pop(context);

                      await _chatService.unsendMessage(
                        currentUserId: currentUser!.uid,
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

  Widget _buildReplyPreviewBar() {
    final replyingTo = _replyingTo;
    if (replyingTo == null || _isBlocked) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.purpleAccent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replySenderLabel(replyingTo)}',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyPreviewText(replyingTo),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _replyingTo = null;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                color: Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedReply(MessageModel message) {
    if (!message.hasReply) return const SizedBox.shrink();

    final repliedToMe =
        currentUser != null && message.replyToSenderId == currentUser!.uid;

    final repliedLabel = repliedToMe ? 'You' : widget.otherUserName;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.35),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            repliedLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message.replyToText ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? dt) {
    if (_isBlocked) return 'unavailable';
    if (dt == null) return 'last seen recently';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'online now';
    } else if (diff.inMinutes < 60) {
      return 'last seen ${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return 'last seen ${diff.inHours} hr ago';
    } else {
      return 'last seen ${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _formatMessageTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);
    final difference = today.difference(messageDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  bool _shouldShowDateHeader(List<MessageModel> messages, int index) {
    if (index == 0) return true;

    final current = messages[index].timestamp;
    final previous = messages[index - 1].timestamp;

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget _buildDateHeader(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xff171717),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDateHeader(dt),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageFooter(MessageModel message) {
    final isMe = currentUser != null && message.senderId == currentUser!.uid;
    final timeText = _formatMessageTime(message.timestamp);

    if (!isMe || message.isUnsent) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          timeText,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeText,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message.isSeen ? 'Seen' : 'Sent',
            style: TextStyle(
              color: message.isSeen ? Colors.white70 : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isMe = message.senderId == currentUser!.uid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: message.isUnsent
                ? const Color(0xff141414)
                : isMe
                    ? Colors.purpleAccent
                    : const Color(0xff1C1C1C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: message.isUnsent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This message was unsent',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    _buildMessageFooter(message),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuotedReply(message),
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    _buildMessageFooter(message),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    if (!_showEmojiPicker || _isBlocked) return const SizedBox.shrink();

    return SizedBox(
      height: 280,
      child: EmojiPicker(
        textEditingController: _messageController,
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: const EmojiViewConfig(
            emojiSizeMax: 28,
            columns: 8,
            backgroundColor: Color(0xff0B0B0B),
          ),
          categoryViewConfig: const CategoryViewConfig(
            backgroundColor: Color(0xff171717),
            iconColorSelected: Colors.purpleAccent,
            iconColor: Colors.white54,
            indicatorColor: Colors.purpleAccent,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            backgroundColor: Color(0xff171717),
            buttonColor: Colors.purpleAccent,
          ),
          searchViewConfig: const SearchViewConfig(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'You cannot send messages in this chat.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildComposer() {
    if (_isBlocked) {
      return _buildBlockedBar();
    }

    return Column(
      children: [
        _buildReplyPreviewBar(),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: const Color(0xff0B0B0B),
          child: Row(
            children: [
              InkWell(
                onTap: _toggleEmojiPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xff171717),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  style: const TextStyle(color: Colors.white),
                  onTap: () {
                    if (_showEmojiPicker) {
                      setState(() {
                        _showEmojiPicker = false;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xff171717),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildEmojiPicker(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
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
        if (_showEmojiPicker) {
          setState(() {
            _showEmojiPicker = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xff0B0B0B),
        appBar: AppBar(
          backgroundColor: const Color(0xff0B0B0B),
          elevation: 0,
          titleSpacing: 0,
          title: StreamBuilder<DateTime?>(
            stream: _userService.watchLastSeen(widget.otherUserId),
            builder: (context, snapshot) {
              final lastSeenText = _formatLastSeen(snapshot.data);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastSeenText,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _checkingBlock
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.purpleAccent,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _chatService.getMessages(
                        user1: currentUser!.uid,
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

                        final messages = snapshot.data ?? [];

                       WidgetsBinding.instance.addPostFrameCallback((_) {
  _scrollToBottom();
});
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

                            return Column(
                              children: [
                                if (_shouldShowDateHeader(messages, index))
                                  _buildDateHeader(message.timestamp),
                                _buildMessageBubble(message),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: _buildComposer(),
                  ),
                ],
              ),
      ),
    );
  }
}