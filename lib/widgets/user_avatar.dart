import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 34,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        user.photoUrl != null && user.photoUrl!.trim().isNotEmpty;

    final firstLetter = user.nickname.isNotEmpty
        ? user.nickname[0].toUpperCase()
        : "?";

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: .15),
          backgroundImage:
              hasPhoto ? NetworkImage(user.photoUrl!) : null,
          child: hasPhoto
              ? null
              : Text(
                  firstLetter,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * .9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),

        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color:
                  user.isOnline ? AppColors.online : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.background,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}