import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

import 'login_screen.dart';
import 'nearby_screen.dart';
import 'chats_screen.dart';
import 'edit_profile_screen.dart';
import 'blocked_users_screen.dart';
import 'notification_settings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'community_guidelines_screen.dart';
import 'help_support_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
final ChatService _chatService = ChatService();
final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  AppUser? userData;
  bool isLoading = true;
  bool isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final user = await _userService.getUser(currentUser!.uid);

    if (!mounted) return;

    setState(() {
      userData = user;
      isLoading = false;
    });
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
      });

      await _loadUser();
    }
  }

  Future<void> _openBlockedUsers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BlockedUsersScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationSettingsScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openAdminPanel() async {
    if (userData?.isAdmin != true) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminDashboardScreen(),
      ),
    );

    if (!mounted) return;

    await _loadUser();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    if (isDeletingAccount) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your account, chats and profile. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isDeletingAccount = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) return;

      await _chatService.deleteCurrentUserChats(uid);
      await _userService.deleteCurrentUserData(uid);
      await _authService.deleteFirebaseAuthAccount();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete account. Please sign in again and retry.'),
        ),
      );
      setState(() {
        isDeletingAccount = false;
      });
    }
  }

  Widget _buildProfileCard() {
    final nickname = userData?.nickname ?? '';
    final gender = userData?.gender ?? '';
    final lookingFor = userData?.lookingFor ?? '';
    final age = userData?.age;

    final subtitleParts = <String>[];

    if (age != null && age > 0) {
      subtitleParts.add('$age yrs');
    }

    if (gender.isNotEmpty) {
      subtitleParts.add(gender);
    } else {
      subtitleParts.add('Not set');
    }

    final subtitleLine = subtitleParts.join(' • ');

    final lookingForText = lookingFor.isNotEmpty
        ? 'Looking for $lookingFor'
        : 'Looking for Not set';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.purpleAccent,
            child: Text(
              nickname.isNotEmpty
                  ? nickname[0].toUpperCase()
                  : "N",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nickname.isNotEmpty
                            ? nickname
                            : "NearMeU User",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (userData?.isAdmin == true) ...[
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.amber,
                        size: 19,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleLine,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lookingForText,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.purpleAccent,
    Color titleColor = Colors.white,
  }) {
    return ListTile(
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xff171717),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const Divider(height: 1, color: Color(0xFF2A2A2A), indent: 56),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.logout,
          color: Colors.redAccent,
        ),
        title: const Text(
          "Logout",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          "Sign out from this device",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        onTap: _logout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xff0B0B0B),
        body: Center(
          child: Text(
            'User not logged in',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xff0B0B0B),
        elevation: 0,
        title: const Text(
          "Settings",
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 28 + MediaQuery.paddingOf(context).bottom),
              children: [
                _buildProfileCard(),
                const SizedBox(height: 24),
                _settingsSection('Account', [
                  _settingTile(icon: Icons.person_outline, title: 'Edit Profile', subtitle: 'Update your profile info', onTap: _openEditProfile),
                ]),
                _settingsSection('Privacy & Safety', [
                  _settingTile(icon: Icons.lock_outline, title: 'Blocked Users', subtitle: 'Manage blocked users and unblock anytime', onTap: _openBlockedUsers),
                ]),
                _settingsSection('Notifications', [
                  _settingTile(icon: Icons.notifications_none, title: 'Notification Settings', subtitle: 'Manage message and nearby alerts', onTap: _openNotifications),
                ]),
                if (userData?.isAdmin == true)
                  _settingsSection('Admin', [
                    _settingTile(icon: Icons.admin_panel_settings, title: 'Admin Panel', subtitle: 'Manage users and view app overview', iconColor: Colors.amber, onTap: _openAdminPanel),
                  ]),
                _settingsSection('Support & Legal', [
                  _settingTile(icon: Icons.info_outline, title: 'About NearMeU', subtitle: 'App version and information', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
                  _settingTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', subtitle: 'Read how we protect your data', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
                  _settingTile(icon: Icons.description_outlined, title: 'Terms & Conditions', subtitle: 'Application terms of use', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
                  _settingTile(icon: Icons.groups_outlined, title: 'Community Guidelines', subtitle: 'Keep NearMeU safe for everyone', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityGuidelinesScreen()))),
                ]),
                _settingsSection('Account Actions', [
                  _settingTile(icon: Icons.logout, iconColor: Colors.orangeAccent, titleColor: Colors.orangeAccent, title: 'Sign Out', subtitle: 'Sign out from this device', onTap: _logout),
                  _settingTile(icon: Icons.delete_forever, iconColor: Colors.redAccent, titleColor: Colors.redAccent, title: 'Delete Account', subtitle: 'Permanently delete your account', onTap: isDeletingAccount ? () {} : _deleteAccount),
                ]),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => NearbyScreen(),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatsScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.location_on,
            ),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.chat_bubble_outline,
            ),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}