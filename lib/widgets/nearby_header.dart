import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NearbyHeader extends StatelessWidget {
  final int nearbyCount;
  final int onlineCount;
  final String distanceLabel;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const NearbyHeader({
    super.key,
    required this.nearbyCount,
    required this.onlineCount,
    required this.distanceLabel,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '$nearbyCount people found, $onlineCount online, filter $distanceLabel',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .20),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;
            final summary = _Summary(
              nearbyCount: nearbyCount,
              onlineCount: onlineCount,
              distanceLabel: distanceLabel,
            );
            final refresh = _RefreshButton(
              isRefreshing: isRefreshing,
              onRefresh: onRefresh,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _HeaderIcon(),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Text(
                          'People Near You',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      refresh,
                    ],
                  ),
                  const SizedBox(height: 14),
                  summary,
                ],
              );
            }

            return Row(
              children: [
                const _HeaderIcon(),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'People Near You',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      summary,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                refresh,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 25),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.nearbyCount,
    required this.onlineCount,
    required this.distanceLabel,
  });

  final int nearbyCount;
  final int onlineCount;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _MiniPill(
          icon: Icons.people_alt_rounded,
          label: '$nearbyCount found',
        ),
        _MiniPill(
          icon: Icons.circle,
          label: '$onlineCount online',
          iconColor: AppColors.online,
        ),
        _MiniPill(icon: Icons.route_rounded, label: distanceLabel),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isRefreshing ? 'Refreshing nearby people' : 'Refresh nearby',
      child: Semantics(
        button: true,
        enabled: !isRefreshing,
        label: isRefreshing ? 'Refreshing nearby people' : 'Refresh nearby',
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: isRefreshing ? null : onRefresh,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isRefreshing ? .10 : .16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isRefreshing
                  ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      key: ValueKey('refresh'),
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _MiniPill({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
