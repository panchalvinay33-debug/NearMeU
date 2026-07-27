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
        builder: (_) => ChatScreen(
          otherUserId: user.uid,
          otherUserName: user.nickname,
          initialPhotoUrl: user.photoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = NearbyUserPresenter.isEffectivelyOnline(user);
    final nickname = user.nickname.trim().isEmpty
        ? 'NearMeU User'
        : user.nickname.trim();
    final status = isOnline ? 'online' : 'offline';
    final distance = distanceText?.trim();
    final age = user.age != null && user.age! > 0 ? '${user.age} years old' : null;

    return Semantics(
      container: true,
      button: true,
      label: [
        nickname,
        if (age != null) age,
        status,
        if (distance != null && distance.isNotEmpty) distance,
        'Open profile',
      ].join(', '),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isOnline
                  ? AppColors.primary.withValues(alpha: .11)
                  : AppColors.surfaceLight.withValues(alpha: .62),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOnline
                ? AppColors.primary.withValues(alpha: .42)
                : AppColors.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
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
                      Hero(
                        tag: 'nearby-avatar-${user.uid}',
                        child: UserAvatar(user: user, radius: 35),
                      ),
                      const SizedBox(width: 14),
                      UserInfo(user: user, distanceText: distanceText),
                      const SizedBox(width: 6),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ExcludeSemantics(
                      child: ChatButton(onTap: () => _openChat(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
