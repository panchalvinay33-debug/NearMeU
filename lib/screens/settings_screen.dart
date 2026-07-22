import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/unread_nav_icon.dart';
import 'about_screen.dart';
import 'admin_dashboard_screen.dart';
import 'blocked_users_screen.dart';
import 'chats_screen.dart';
import 'community_guidelines_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
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
    final uid = currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final user = await _userService.getUser(uid);
    if (!mounted) return;
    setState(() {
      userData = user;
      isLoading = false;
    });
  }

  Future<void> _open(Widget screen, {bool reloadUser = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (!mounted) return;
    if (reloadUser) await _loadUser();
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
    if (isDeletingAccount) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This permanently deletes your profile and chats. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => isDeletingAccount = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
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
      setState(() => isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete account. Please sign in again and retry.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _ProfileCard(user: userData),
                const SizedBox(height: 26),
                _Section(
                  title: 'Account',
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your profile info',
                      onTap: () => _open(
                        const EditProfileScreen(),
                        reloadUser: true,
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'Privacy & Safety',
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Blocked Users',
                      subtitle: 'Manage blocked users and unblock anytime',
                      onTap: () => _open(const BlockedUsersScreen()),
                    ),
                  ],
                ),
                _Section(
                  title: 'Notifications',
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notification Settings',
                      subtitle: 'Manage message and nearby alerts',
                      onTap: () => _open(const NotificationSettingsScreen()),
                    ),
                  ],
                ),
                if (userData?.isAdmin == true)
                  _Section(
                    title: 'Admin',
                    children: [
                      _SettingsTile(
                        icon: Icons.admin_panel_settings_rounded,
                        iconColor: Colors.amber,
                        title: 'Admin Panel',
                        subtitle: 'Manage users and view app overview',
                        onTap: () => _open(
                          const AdminDashboardScreen(),
                          reloadUser: true,
                        ),
                      ),
                    ],
                  ),
                _Section(
                  title: 'Support & Legal',
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About NearMeU',
                      subtitle: 'App version and information',
                      onTap: () => _open(const AboutScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Read how we protect your data',
                      onTap: () => _open(const PrivacyPolicyScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Application terms of use',
                      onTap: () => _open(const TermsScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.groups_outlined,
                      title: 'Community Guidelines',
                      subtitle: 'Keep NearMeU safe for everyone',
                      onTap: () => _open(const CommunityGuidelinesScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Help & Support',
                      subtitle: 'FAQ and contact support',
                      onTap: () => _open(const HelpSupportScreen()),
                    ),
                  ],
                ),
                _Section(
                  title: 'Account Actions',
                  children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.orangeAccent,
                      title: 'Sign Out',
                      subtitle: 'Sign out from this device',
                      titleColor: Colors.orangeAccent,
                      onTap: _logout,
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.redAccent,
                      title: isDeletingAccount ? 'Deleting…' : 'Delete Account',
                      subtitle: 'Permanently delete your account',
                      titleColor: Colors.redAccent,
                      onTap: isDeletingAccount ? null : _deleteAccount,
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: AppColors.primary,
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
            icon: UnreadNavIcon(
              userId: uid,
              icon: Icons.chat_bubble_outline,
            ),
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final nickname = user?.nickname.trim().isNotEmpty == true
        ? user!.nickname.trim()
        : 'NearMeU User';
    final gender = user?.gender.trim().isNotEmpty == true ? user!.gender : 'Not set';
    final lookingFor = user?.lookingFor.trim().isNotEmpty == true
        ? user!.lookingFor
        : 'Not set';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24143B), Color(0xFF151821)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            child: Text(
              nickname.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (user?.isAdmin == true) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${user?.age ?? 0} yrs • $gender',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Looking for $lookingFor',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.titleColor = Colors.white,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: ListTile(
        minVerticalPadding: 17,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
