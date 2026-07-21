import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats =
          await _userService.getAdminDashboardStats();

      if (!mounted) return;

      setState(() {
        _totalUsers = stats["total"] ?? 0;
        _onlineUsers = stats["online"] ?? 0;
        _offlineUsers = stats["offline"] ?? 0;
        _suspendedUsers =
            stats["suspended"] ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          CircleAvatar(
            backgroundColor:
                color.withValues(alpha: .15),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const Spacer(),

          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 16,
        ),
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff171717),
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color: Colors.white12,
          ),
        ),
        child: Row(
          children: [

            CircleAvatar(
              radius: 26,
              backgroundColor:
                  color.withValues(alpha: .15),
              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    title,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      color:
                          Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [

                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 55,
                        ),

                        const SizedBox(height: 20),

                        Text(
                          _error!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed:
                              _loadStats,
                          child: const Text(
                            "Retry",
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    children: [

                      const Text(
                        "NearMeU Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Complete control panel",
                        style: TextStyle(
                          color:
                              Colors.white54,
                        ),
                      ),

                      const SizedBox(height: 25),

                      GridView.count(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.1,
                        children: [

                          _buildStatCard(
                            title:
                                "Total Users",
                            value:
                                _totalUsers,
                            icon:
                                Icons.people,
                            color:
                                Colors.blue,
                          ),

                          _buildStatCard(
                            title:
                                "Online",
                            value:
                                _onlineUsers,
                            icon: Icons
                                .wifi,
                            color:
                                Colors.green,
                          ),

                          _buildStatCard(
                            title:
                                "Offline",
                            value:
                                _offlineUsers,
                            icon: Icons
                                .person_off,
                            color:
                                Colors.orange,
                          ),

                          _buildStatCard(
                            title:
                                "Suspended",
                            value:
                                _suspendedUsers,
                            icon:
                                Icons.block,
                            color:
                                Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        "Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildMenuCard(
                        title:
                            "Manage Users",
                        subtitle:
                            "View, suspend and restore users",
                        icon: Icons
                            .manage_accounts,
                        color:
                            Colors.purple,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminUsersScreen(),
                            ),
                          );

                          _loadStats();
                        },
                      ),

                      _buildMenuCard(
                        title:
                            "User Reports",
                        subtitle:
                            "Review reported accounts",
                        icon:
                            Icons.flag,
                        color: Colors.red,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminReportsScreen(),
                            ),
                          );

                          _loadStats();
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildMenuCard(
                        title: "Coming Soon",
                        subtitle:
                            "Analytics, reports, moderation logs and more",
                        icon: Icons.analytics_outlined,
                        color: Colors.teal,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "More admin tools coming soon.",
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xff171717),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [

                            Icon(
                              Icons.security,
                              color: Colors.green,
                              size: 40,
                            ),

                            SizedBox(height: 12),

                            Text(
                              "Admin Security",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              "Private chats are never visible in the admin panel. "
                              "Only user accounts, reports and moderation actions "
                              "can be managed.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Center(
                        child: Text(
                          "NearMeU Admin v1.0",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
    );
  }
}