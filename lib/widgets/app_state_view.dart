import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 58 : 72,
          height: compact ? 58 : 72,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(compact ? 18 : 24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: compact ? 28 : 34),
        ),
        SizedBox(height: compact ? 14 : 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (actionLabel != null && onAction != null) ...<Widget>[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 20 : 28),
        child: content,
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class AppPrivacyNotice extends StatelessWidget {
  const AppPrivacyNotice({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: .24)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.shield_outlined, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your private content stays protected inside NearMeU.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 12 : 13,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
