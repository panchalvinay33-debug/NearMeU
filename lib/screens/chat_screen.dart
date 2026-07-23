import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
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
  bool _isSending = false;

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

    if (text.isEmpty) return;

    if (currentUser == null) return;

    if (_isBlocked || _isSending) return;

    setState(() {
      _isSending = true;
    });

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
    } catch (error) {
      await _checkBlockStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _replyPreviewText(MessageModel message) {
    if (message.isUnsent) {
      return "This message was unsent";
    }

    final text = message.text.trim();

    if (text.isEmpty) {
      return "Message";
    }

    if (text.length > 60) {
      return "${text.substring(0, 60)}...";
    }

    return text;
  }

  String _replySenderLabel(MessageModel message) {
    if (currentUser != null && message.senderId == currentUser!.uid) {
      return "You";
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

    if (message.text.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: message.text.trim()));

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Message copied")));
  }

  Future<void> _deleteForMe(MessageModel message) async {
    if (currentUser == null) return;

    await _chatService.deleteMessageForMe(
      currentUserId: currentUser!.uid,
      otherUserId: widget.otherUserId,
      message: message,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Message deleted for you")));
  }

  Future<void> _showMessageOptions(MessageModel message) async {
    if (currentUser == null) return;

    final canUnsend = message.canUnsend(currentUser!.uid);

    final isMe = message.senderId == currentUser!.uid;

    await showModalBottomSheet(
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
                      "Reply",
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
                      "Copy",
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
                    "Delete for me",
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
                      "Unsend",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "Remove for both users",
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

  String _formatLastSeen(DateTime? dt) {
    if (_isBlocked) {
      return "Unavailable";
    }

    if (dt == null) {
      return "Last seen recently";
    }

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return "Last seen just now";
    }

    if (diff.inMinutes < 60) {
      return "Last seen ${diff.inMinutes} min ago";
    }

    if (diff.inHours < 24) {
      return "Last seen ${diff.inHours} hr ago";
    }

    return "Last seen ${dt.day}/${dt.month}/${dt.year}";
  }

  String _formatMessageTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;

    final minute = dt.minute.toString().padLeft(2, '0');

    final period = dt.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final messageDay = DateTime(dt.year, dt.month, dt.day);

    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      return "Today";
    }

    if (difference == 1) {
      return "Yesterday";
    }

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  bool _shouldShowDateHeader(List<MessageModel> messages, int index) {
    if (index == 0) {
      return true;
    }

    final current = messages[index].timestamp;

    final previous = messages[index - 1].timestamp;

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null || _isBlocked) {
      return const SizedBox.shrink();
    }

    return ReplyPreview(
      replyingTo: _replyingTo!,
      senderName: _replySenderLabel(_replyingTo!),
      previewText: _replyPreviewText(_replyingTo!),
      onClose: () {
        setState(() {
          _replyingTo = null;
        });
      },
    );
  }

  Widget _buildEmojiPicker() {
    if (!_showEmojiPicker || _isBlocked) {
      return const SizedBox.shrink();
    }

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
            iconColorSelected: AppColors.primary,
            iconColor: Colors.white54,
            indicatorColor: AppColors.primary,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            backgroundColor: Color(0xff171717),
            buttonColor: AppColors.primary,
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        "You cannot send messages in this chat.",
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _buildComposer() {
    if (_isBlocked) {
      return _buildBlockedBar();
    }

    return Column(
      children: [
        ChatComposer(
          controller: _messageController,
          focusNode: _messageFocusNode,
          showEmojiPicker: _showEmojiPicker,
          onEmojiTap: _toggleEmojiPicker,
          onSend: _isSending ? null : _sendMessage,
          onTextFieldTap: () {
            if (_showEmojiPicker) {
              setState(() {
                _showEmojiPicker = false;
              });
            }
          },
          replyPreview: _replyingTo == null ? null : _buildReplyPreview(),
        ),

        _buildEmojiPicker(),
      ],
    );
  }

  Future<void> _showReportDialog() async {
    if (currentUser == null) return;

    String selectedReason = "Spam";
    final descriptionController = TextEditingController();

    final reasons = [
      "Spam",
      "Fake Profile",
      "Harassment",
      "Hate Speech",
      "Scam/Fraud",
      "Inappropriate Content",
      "Other",
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                "Report User",
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
                      items: reasons.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          selectedReason = v;
                        });
                      },
                    ),

                    if (selectedReason == "Other") const SizedBox(height: 16),

                    if (selectedReason == "Other")
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Describe the problem",
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    try {
                      await _userService.reportUser(
                        reporterId: currentUser!.uid,

                        reportedUserId: widget.otherUserId,

                        reason: selectedReason,

                        description: descriptionController.text.trim(),
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("User reported successfully."),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Text("Report"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openOtherUserProfile() async {
    try {
      final profile = await _userService.getUser(widget.otherUserId);

      if (!mounted) return;

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile is not available right now.")),
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
        const SnackBar(content: Text("Could not open this profile.")),
      );
    }
  }

  Future<void> _showChatMenu() async {
    await showModalBottomSheet(
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
                  "Report User",
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
                  "View Profile",
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
                  "Block User",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  if (currentUser == null) return;

                  await _userService.blockUser(
                    currentUserId: currentUser!.uid,
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
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "User not logged in",
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: StreamBuilder<AppUser?>(
            stream: _userService.streamUser(widget.otherUserId),
            builder: (context, snapshot) {
              final otherUser = snapshot.data;
              final isOnline =
                  !_isBlocked &&
                  otherUser != null &&
                  NearbyUserPresenter.isEffectivelyOnline(otherUser);

              return ChatAppBar(
                userName: widget.otherUserName,
                lastSeen: isOnline
                    ? "Online"
                    : _formatLastSeen(otherUser?.lastSeen),
                isOnline: isOnline,
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
                              "Error : ${snapshot.error}",
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
                              "No messages yet 👋",
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

                            final isMe = message.senderId == currentUser!.uid;

                            final repliedToMe =
                                message.replyToSenderId == currentUser!.uid;

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
