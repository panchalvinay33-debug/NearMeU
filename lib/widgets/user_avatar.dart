import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_colors.dart';
import '../utils/nearby_user_presenter.dart';

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 34});

  List<Color> get _genderGradient {
    switch (user.gender.trim().toLowerCase()) {
      case 'male':
        return const [Color(0xFF2563EB), Color(0xFF06B6D4)];
      case 'female':
        return const [Color(0xFFEC4899), Color(0xFFA855F7)];
      default:
        return const [Color(0xFF8B5CF6), Color(0xFFF59E0B)];
    }
  }

  IconData get _genderIcon {
    switch (user.gender.trim().toLowerCase()) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _fallback() {
    final firstLetter = user.nickname.trim().isEmpty
        ? '?'
        : user.nickname.trim()[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _genderGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.88,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isOnline = NearbyUserPresenter.isEffectivelyOnline(user);
    final size = radius * 2;

    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: _genderGradient),
              boxShadow: [
                BoxShadow(
                  color: _genderGradient.last.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: AppColors.surfaceLight,
                child: hasPhoto
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
          ),
          Positioned(
            left: -1,
            bottom: 1,
            child: Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _genderGradient),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Icon(_genderIcon, size: 14, color: Colors.white),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.online.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
