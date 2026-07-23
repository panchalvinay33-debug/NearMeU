import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/chat_screen.dart';
import '../screens/user_profile_screen.dart';
import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';
import 'chat_button.dart';
import 'user_avatar.dart';
import 'user_info.dart';

class NearbyUserCard extends StatelessWidget {
  final AppUser user;
  final String? distanceText;

  const NearbyUserCard({super.key, required this.user, this.distanceText});

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(otherUserId: user.uid, otherUserName: user.nickname),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = NearbyUserPresenter.isEffectivelyOnline(user);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isOnline
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.surfaceLight.withValues(alpha: 0.62),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOnline
              ? AppColors.primary.withValues(alpha: 0.44)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openProfile(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(user: user, radius: 35),
                    const SizedBox(width: 14),
                    UserInfo(user: user, distanceText: distanceText),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ChatButton(onTap: () => _openChat(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
