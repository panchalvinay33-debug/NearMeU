import 'package:flutter/material.dart';

import '../services/user_service.dart';
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final stats =
          await _userService.getAdminDashboardStats();

      if (!mounted) return;

      setState(() {
        _totalUsers = stats['total'] ?? 0;
        _onlineUsers = stats['online'] ?? 0;
        _offlineUsers = stats['offline'] ?? 0;
        _suspendedUsers = stats['suspended'] ?? 0;
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
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.purpleAccent,
            size: 30,
          ),
          const SizedBox(height: 18),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B0B0B),
        elevation: 0,
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
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
              child:
                  CircularProgressIndicator(
                color:
                    Colors.purpleAccent,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          _error!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          onPressed:
                              _loadStats,
                          child: const Text(
                            'Retry',
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
                        'NearMeU Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      const Text(
                        'User activity and account management',
                        style: TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio:
                            1.15,
                        children: [
                          _buildStatCard(
                            title:
                                'Total Users',
                            value:
                                _totalUsers,
                            icon:
                                Icons.people,
                          ),
                          _buildStatCard(
                            title:
                                'Online Users',
                            value:
                                _onlineUsers,
                            icon: Icons
                                .circle,
                          ),
                          _buildStatCard(
                            title:
                                'Offline Users',
                            value:
                                _offlineUsers,
                            icon: Icons
                                .person_off_outlined,
                          ),
                          _buildStatCard(
                            title:
                                'Suspended',
                            value:
                                _suspendedUsers,
                            icon: Icons
                                .block,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 28,
                      ),
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
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
                        child: Container(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF171717,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                            border:
                                Border.all(
                              color: Colors
                                  .white12,
                            ),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    Colors
                                        .purpleAccent,
                                child: Icon(
                                  Icons
                                      .manage_accounts,
                                  color: Colors
                                      .white,
                                ),
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Manage Users',
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .white,
                                        fontSize:
                                            18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      'View, search, suspend or restore accounts',
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .white60,
                                        fontSize:
                                            13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons
                                    .chevron_right,
                                color: Colors
                                    .white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      const Center(
                        child: Text(
                          'Private chats are not shown in Admin Panel',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}