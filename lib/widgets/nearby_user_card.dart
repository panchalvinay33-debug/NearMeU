import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/chat_screen.dart';
import '../screens/user_profile_screen.dart';
import '../theme/app_colors.dart';
import 'chat_button.dart';
import 'user_avatar.dart';
import 'user_info.dart';

class NearbyUserCard extends StatelessWidget {
  final AppUser user;
  final String? distanceText;

  const NearbyUserCard({
    super.key,
    required this.user,
    this.distanceText,
  });

  void _openProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: user.uid,
          otherUserName: user.nickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openProfile(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    UserAvatar(user: user),

                    const SizedBox(width: 14),

                    UserInfo(
                      user: user,
                      distanceText: distanceText,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ChatButton(
                    onTap: () => _openChat(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}