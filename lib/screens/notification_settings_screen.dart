import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

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

  bool messageNotificationsEnabled = true;
  bool nearbyAlertsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final AppUser? user = await _userService.getUser(currentUser!.uid);

    if (!mounted) return;

    setState(() {
      messageNotificationsEnabled =
          user?.messageNotificationsEnabled ?? true;
      nearbyAlertsEnabled = user?.nearbyAlertsEnabled ?? false;
      isLoading = false;
    });
  }

  Future<void> _toggleMessageNotifications(bool value) async {
    if (currentUser == null) return;

    setState(() {
      isSavingMessages = true;
      messageNotificationsEnabled = value;
    });

    await _userService.updateMessageNotifications(
      uid: currentUser!.uid,
      enabled: value,
    );

    if (!mounted) return;

    setState(() {
      isSavingMessages = false;
    });
  }

  Future<void> _toggleNearbyAlerts(bool value) async {
    if (currentUser == null) return;

    setState(() {
      isSavingNearby = true;
      nearbyAlertsEnabled = value;
    });

    await _userService.updateNearbyAlerts(
      uid: currentUser!.uid,
      enabled: value,
    );

    if (!mounted) return;

    setState(() {
      isSavingNearby = false;
    });
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isSaving = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purpleAccent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isSaving)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.purpleAccent,
              ),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.purpleAccent,
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'These settings save your notification preferences in NearMeU. Push notification delivery can be connected later without changing your app design.',
        style: TextStyle(
          color: Colors.white60,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('CHAT NOTIFICATIONS'),
                _switchTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'New Message Notifications',
                  subtitle: 'Get alerts when someone sends you a new message',
                  value: messageNotificationsEnabled,
                  onChanged: _toggleMessageNotifications,
                  isSaving: isSavingMessages,
                ),
                const SizedBox(height: 8),
                _sectionTitle('DISCOVERY ALERTS'),
                _switchTile(
                  icon: Icons.location_on_outlined,
                  title: 'Nearby Alerts',
                  subtitle: 'Get alerts when new nearby users may match you',
                  value: nearbyAlertsEnabled,
                  onChanged: _toggleNearbyAlerts,
                  isSaving: isSavingNearby,
                ),
                _infoCard(),
              ],
            ),
    );
  }
}