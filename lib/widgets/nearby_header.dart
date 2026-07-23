import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NearbyHeader extends StatelessWidget {
  final int nearbyCount;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const NearbyHeader({
    super.key,
    required this.nearbyCount,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .14)),
            ),
            child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'People near you',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$nearbyCount people available',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .76),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Refresh people',
            onPressed: isRefreshing ? null : onRefresh,
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              backgroundColor: Colors.white.withValues(alpha: .14),
              foregroundColor: Colors.white,
            ),
            icon: isRefreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}
