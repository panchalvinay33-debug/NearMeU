import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import 'linkified_message_text.dart';
import 'message_footer.dart';
import 'quoted_reply.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool repliedToMe;
  final String otherUserName;
  final String time;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.repliedToMe,
    required this.otherUserName,
    required this.time,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .78,
          ),
          decoration: BoxDecoration(
            gradient: message.isUnsent
                ? null
                : isMe
                    ? const LinearGradient(
                        colors: [Color(0xff8E2DE2), Color(0xff6A1BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: message.isUnsent
                ? const Color(0xff141414)
                : isMe
                    ? null
                    : const Color(0xff1C1C1C),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: message.isUnsent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This message was unsent',
                      style: TextStyle(
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                      ),
                    ),
                    MessageFooter(message: message, isMe: isMe, time: time),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuotedReply(
                      message: message,
                      repliedToMe: repliedToMe,
                      otherUserName: otherUserName,
                    ),
                    LinkifiedMessageText(
                      text: message.text,
                      baseStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                    ),
                    MessageFooter(message: message, isMe: isMe, time: time),
                  ],
                ),
        ),
      ),
    );
  }
}
