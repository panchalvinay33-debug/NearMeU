import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String lastSeen;
  final bool isOnline;
  final String? photoUrl;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final VoidCallback? onAudioCall;
  final bool audioCallLoading;
  final VoidCallback? onMenu;

  const ChatAppBar({
    super.key,
    required this.userName,
    required this.lastSeen,
    required this.isOnline,
    this.photoUrl,
    this.onBack,
    this.onProfile,
    this.onAudioCall,
    this.audioCallLoading = false,
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
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onProfile,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
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
                                    errorBuilder: (_, __, ___) =>
                                        _fallbackAvatar(),
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
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
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
                              fontSize: 18,
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
                              fontSize: 12,
                              fontWeight: isOnline
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Audio call',
            onPressed: audioCallLoading ? null : onAudioCall,
            icon: audioCallLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.call_rounded),
            color: AppColors.textPrimary,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onMenu,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
