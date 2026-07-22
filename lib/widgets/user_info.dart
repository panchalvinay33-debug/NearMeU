import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';

class UserInfo extends StatelessWidget {
  final AppUser user;
  final String? distanceText;

  const UserInfo({
    super.key,
    required this.user,
    this.distanceText,
  });

  String _location() {
    if (user.state != null && user.state!.trim().isNotEmpty) {
      return user.state!.trim();
    }

    return "Location unavailable";
  }

  @override
  Widget build(BuildContext context) {
    final age =
        (user.age != null && user.age! > 0) ? ", ${user.age}" : "";

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "${user.nickname}$age",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _location(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: user.isOnline
                    ? AppColors.online
                    : Colors.grey,
              ),
              const SizedBox(width: 6),

              Text(
                user.isOnline ? "Online" : "Offline",
                style: TextStyle(
                  color: user.isOnline
                      ? AppColors.online
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              if (distanceText != null) ...[
                const SizedBox(width: 12),

                const Icon(
                  Icons.near_me,
                  size: 14,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 4),

                Text(
                  distanceText!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}