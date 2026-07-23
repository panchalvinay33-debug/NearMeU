import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/chat_screen.dart';
import '../screens/user_profile_screen.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';

class NearbyUserCard extends StatelessWidget {
  final AppUser user;
  final String? distanceText;

  const NearbyUserCard({
    super.key,
    required this.user,
    this.distanceText,
  });

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: user.uid,
          otherUserName: user.nickname,
        ),
      ),
    );
  }

  IconData get _genderIcon {
    switch (user.gender.toLowerCase()) {
      case 'female':
        return Icons.female_rounded;
      case 'male':
        return Icons.male_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String get _activityText {
    if (user.isOnline) return 'Online now';
    final lastSeen = user.lastSeen;
    if (lastSeen == null) return 'Offline';
    final difference = DateTime.now().difference(lastSeen);
    if (difference.inMinutes < 2) return 'Active recently';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final age = user.age != null && user.age! > 0 ? ', ${user.age}' : '';
    final location = (distanceText?.trim().isNotEmpty ?? false)
        ? distanceText!
        : 'Distance unavailable';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
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
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openProfile(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(user: user, radius: 29),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.nickname}$age',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _genderIcon,
                              size: 17,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            height: 7,
                            width: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user.isOnline
                                  ? AppColors.online
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _activityText,
                            style: TextStyle(
                              color: user.isOnline
                                  ? AppColors.online
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Chat with ${user.nickname}',
                  onPressed: () => _openChat(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
