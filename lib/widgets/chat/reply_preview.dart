import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class ReplyPreview extends StatelessWidget {
  final MessageModel replyingTo;
  final String senderName;
  final String previewText;
  final VoidCallback onClose;

  const ReplyPreview({
    super.key,
    required this.replyingTo,
    required this.senderName,
    required this.previewText,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff1E1E1E),
            Color(0xff141414),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(.45),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 5,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.purpleAccent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Replying to $senderName",
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  previewText,
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

          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}