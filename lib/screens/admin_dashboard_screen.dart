import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../utils/nearby_user_presenter.dart';
import 'admin_announcement_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  String? _error;
  int _totalUsers = 0;
  int _onlineUsers = 0;
  int _offlineUsers = 0;
  int _suspendedUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final users = await _userService.getAllUsersForAdmin().first;
      final now = DateTime.now();
      final suspended = users.where((user) => user.isSuspended).length;
      final online = users.where((user) {
        return !user.isSuspended &&
            NearbyUserPresenter.isEffectivelyOnline(user, now: now);
      }).length;
      final activeUsers = users.length - suspended;

      if (!mounted) return;
      setState(() {
        _totalUsers = users.length;
        _onlineUsers = online;
        _offlineUsers = (activeUsers - online).clamp(0, activeUsers);
        _suspendedUsers = suspended;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load admin statistics. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _isLoading ? null : _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purpleAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red),
              const SizedBox(height: 18),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const Text(
            'NearMeU Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Complete control panel',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 26),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.04,
            children: [
              _StatCard(
                title: 'Total Users',
                value: _totalUsers,
                icon: Icons.people_rounded,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Online now',
                value: _onlineUsers,
                icon: Icons.wifi_rounded,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Offline',
                value: _offlineUsers,
                icon: Icons.person_off_rounded,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Suspended',
                value: _suspendedUsers,
                icon: Icons.block_rounded,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _MenuCard(
            title: 'Manage Users',
            subtitle: 'View, suspend and restore users',
            icon: Icons.manage_accounts_rounded,
            color: Colors.purple,
            onTap: () => _open(const AdminUsersScreen()),
          ),
          _MenuCard(
            title: 'Send NearMeU Announcement',
            subtitle: 'Broadcast official updates to active users',
            icon: Icons.campaign_rounded,
            color: Colors.purpleAccent,
            onTap: () => _open(const AdminAnnouncementScreen()),
          ),
          _MenuCard(
            title: 'User Reports',
            subtitle: 'Review reported accounts',
            icon: Icons.flag_rounded,
            color: Colors.red,
            onTap: () => _open(const AdminReportsScreen()),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Icon(Icons.security_rounded, color: Colors.green, size: 42),
                SizedBox(height: 12),
                Text(
                  'Admin Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Private chats are never visible in the admin panel. Only user accounts, reports and moderation actions can be managed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .15),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        minVerticalPadding: 18,
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: color.withValues(alpha: .15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, height: 1.35),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
