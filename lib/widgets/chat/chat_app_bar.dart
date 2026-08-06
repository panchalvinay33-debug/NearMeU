import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String lastSeen;
  final bool isOnline;
  final String? photoUrl;
  final VoidCallback? onBack;
  final VoidCallback? onAudioCall;
  final VoidCallback? onMenu;

  const ChatAppBar({
    super.key,
    required this.userName,
    required this.lastSeen,
    required this.isOnline,
    this.photoUrl,
    this.onBack,
    this.onAudioCall,
    this.onMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  Widget _fallbackAvatar() {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        userName.isEmpty ? '?' : userName[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            icon,
            color: onTap == null ? Colors.white30 : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedPhotoUrl = photoUrl?.trim();
    final hasPhoto = normalizedPhotoUrl?.isNotEmpty == true;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: 12,
      title: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onBack ?? () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? Image.network(
                          normalizedPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackAvatar(),
                        )
                      : _fallbackAvatar(),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastSeen,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isOnline
                        ? AppColors.online
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isOnline ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _actionButton(
            icon: Icons.call_rounded,
            onTap: onAudioCall,
            tooltip: 'Audio call',
          ),
          const SizedBox(width: 6),
          _actionButton(
            icon: Icons.more_vert,
            onTap: onMenu,
            tooltip: 'More',
          ),
        ],
      ),
    );
  }
}
