import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/chat_tab_badge.dart';
import 'about_screen.dart';
import 'admin_dashboard_screen.dart';
import 'blocked_users_screen.dart';
import 'chats_screen.dart';
import 'community_guidelines_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'nearby_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  AppUser? _userData;
  bool _isLoading = true;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final user = await _userService.getUser(currentUser.uid);
    if (!mounted) return;
    setState(() {
      _userData = user;
      _isLoading = false;
    });
  }

  Future<void> _openEditProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true && mounted) {
      setState(() => _isLoading = true);
      await _loadUser();
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This permanently deletes your account, chats and profile. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isDeletingAccount = true);

    try {
      final uid = _currentUser?.uid;
      if (uid == null) return;

      await _chatService.deleteCurrentUserChats(uid);
      await _userService.deleteCurrentUserData(uid);
      await _authService.deleteFirebaseAuthAccount();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete account. Please sign in again and retry.',
          ),
        ),
      );
    }
  }

  Widget _profileCard() {
    final nickname = _userData?.nickname.trim() ?? '';
    final gender = _userData?.gender.trim() ?? '';
    final lookingFor = _userData?.lookingFor.trim() ?? '';
    final age = _userData?.age;

    final details = <String>[
      if (age != null && age > 0) '$age yrs',
      if (gender.isNotEmpty) gender else 'Not set',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.purpleAccent,
            child: Text(
              nickname.isEmpty ? 'N' : nickname[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nickname.isEmpty ? 'NearMeU User' : nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_userData?.isAdmin == true) ...[
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.amber,
                        size: 19,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(details, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 3),
                Text(
                  'Looking for ${lookingFor.isEmpty ? 'Not set' : lookingFor}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.purpleAccent,
    Color titleColor = Colors.white,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    const Divider(
                      height: 1,
                      color: Color(0xFF2A2A2A),
                      indent: 56,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B0B),
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                36 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _profileCard(),
                const SizedBox(height: 24),
                _section('Account', [
                  _tile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your profile info',
                    onTap: _openEditProfile,
                  ),
                ]),
                _section('Privacy & Safety', [
                  _tile(
                    icon: Icons.lock_outline,
                    title: 'Blocked Users',
                    subtitle: 'Manage blocked users and unblock anytime',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BlockedUsersScreen(),
                      ),
                    ),
                  ),
                ]),
                _section('Notifications', [
                  _tile(
                    icon: Icons.notifications_none,
                    title: 'Notification Settings',
                    subtitle: 'Manage message and nearby alerts',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                ]),
                if (_userData?.isAdmin == true)
                  _section('Admin', [
                    _tile(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Panel',
                      subtitle: 'Manage users and view app overview',
                      iconColor: Colors.amber,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      ),
                    ),
                  ]),
                _section('Support & Legal', [
                  _tile(
                    icon: Icons.info_outline,
                    title: 'About NearMeU',
                    subtitle: 'App version and information',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                  ),
                  _tile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read how we protect your data',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  _tile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'Application terms of use',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsScreen()),
                    ),
                  ),
                  _tile(
                    icon: Icons.groups_outlined,
                    title: 'Community Guidelines',
                    subtitle: 'Keep NearMeU safe for everyone',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityGuidelinesScreen(),
                      ),
                    ),
                  ),
                ]),
                _section('Account Actions', [
                  _tile(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out from this device',
                    iconColor: Colors.orangeAccent,
                    titleColor: Colors.orangeAccent,
                    onTap: _logout,
                  ),
                  _tile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    iconColor: Colors.redAccent,
                    titleColor: Colors.redAccent,
                    onTap: _isDeletingAccount ? () {} : _deleteAccount,
                  ),
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
              MaterialPageRoute(builder: (_) => const NearbyScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChatsScreen()),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: ChatTabBadge(userId: currentUser.uid),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
