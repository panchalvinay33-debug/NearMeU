
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChatButton extends StatelessWidget {
  final VoidCallback onTap;

  const ChatButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 18,
        ),
        label: const Text(
          "Chat",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}