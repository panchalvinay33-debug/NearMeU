import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_view.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool isLoading = true;
  bool isSavingMessages = false;
  bool isSavingNearby = false;
  bool hasLoadError = false;

  bool messageNotificationsEnabled = true;
  bool nearbyAlertsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasLoadError = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        hasLoadError = false;
      });
    }

    try {
      final AppUser? profile = await _userService.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        messageNotificationsEnabled =
            profile?.messageNotificationsEnabled ?? true;
        nearbyAlertsEnabled = profile?.nearbyAlertsEnabled ?? false;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasLoadError = true;
      });
    }
  }

  Future<void> _toggleMessageNotifications(bool value) async {
    final user = currentUser;
    if (user == null || isSavingMessages) return;

    setState(() {
      isSavingMessages = true;
      messageNotificationsEnabled = value;
    });

    try {
      await _userService.updateMessageNotifications(
        uid: user.uid,
        enabled: value,
      );
      if (!mounted) return;
      _showSavedMessage(
        value ? 'Message notifications enabled.' : 'Message notifications muted.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => messageNotificationsEnabled = !value);
      _showSavedMessage('Could not update this setting. Please retry.');
    } finally {
      if (mounted) setState(() => isSavingMessages = false);
    }
  }

  Future<void> _toggleNearbyAlerts(bool value) async {
    final user = currentUser;
    if (user == null || isSavingNearby) return;

    setState(() {
      isSavingNearby = true;
      nearbyAlertsEnabled = value;
    });

    try {
      await _userService.updateNearbyAlerts(uid: user.uid, enabled: value);
      if (!mounted) return;
      _showSavedMessage(
        value ? 'Nearby alerts enabled.' : 'Nearby alerts muted.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => nearbyAlertsEnabled = !value);
      _showSavedMessage('Could not update this setting. Please retry.');
    } finally {
      if (mounted) setState(() => isSavingNearby = false);
    }
  }

  void _showSavedMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isLoading
              ? const AppLoadingView(label: 'Loading notification settings…')
              : hasLoadError
                  ? AppStateView(
                      icon: Icons.notifications_off_outlined,
                      title: 'Could not load settings',
                      message:
                          'Check your connection and try again. Your existing preferences have not changed.',
                      actionLabel: 'Retry',
                      onAction: _loadSettings,
                    )
                  : ListView(
                      key: const ValueKey<String>('notification-settings'),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        28 + MediaQuery.paddingOf(context).bottom,
                      ),
                      children: <Widget>[
                        const _HeaderCard(),
                        const SizedBox(height: 24),
                        const _SectionTitle('YOUR CHOICES'),
                        _PreferenceTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Private messages',
                          subtitle:
                              'Receive a privacy-safe alert when a new chat message arrives.',
                          value: messageNotificationsEnabled,
                          isSaving: isSavingMessages,
                          onChanged: _toggleMessageNotifications,
                        ),
                        const SizedBox(height: 12),
                        _PreferenceTile(
                          icon: Icons.location_on_outlined,
                          title: 'Nearby discovery alerts',
                          subtitle:
                              'Receive occasional alerts when nearby discovery changes.',
                          value: nearbyAlertsEnabled,
                          isSaving: isSavingNearby,
                          onChanged: _toggleNearbyAlerts,
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle('ALWAYS IMPORTANT'),
                        const _SystemNoticeTile(
                          icon: Icons.campaign_outlined,
                          title: 'Official announcements',
                          subtitle:
                              'Important product, maintenance and safety updates may still be delivered.',
                        ),
                        const SizedBox(height: 12),
                        const _SystemNoticeTile(
                          icon: Icons.system_update_alt_rounded,
                          title: 'Required app updates',
                          subtitle:
                              'Mandatory update and account-security notices cannot be disabled.',
                        ),
                        const SizedBox(height: 18),
                        const AppPrivacyNotice(),
                        const SizedBox(height: 14),
                        Text(
                          'Android notification permission must also be enabled in your phone settings. NearMeU never includes private message content in push notifications.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF25143E), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Stay informed, not overwhelmed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose the optional alerts that are useful to you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSaving,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: <Widget>[
            _TileIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isSaving)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _SystemNoticeTile extends StatelessWidget {
  const _SystemNoticeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            _TileIcon(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.lock_outline_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: AppColors.primaryLight),
    );
  }
}
