import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  final UserService _userService =
      UserService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _changeSuspendedStatus(
    AppUser user,
  ) async {
    final bool newStatus =
        !user.isSuspended;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1A1A1A),
          title: Text(
            newStatus
                ? 'Suspend User?'
                : 'Restore User?',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            newStatus
                ? 'Suspend ${user.nickname.isEmpty ? 'this user' : user.nickname}? The account will be hidden from Nearby.'
                : 'Restore ${user.nickname.isEmpty ? 'this user' : user.nickname}?',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                newStatus
                    ? 'Suspend'
                    : 'Restore',
                style: TextStyle(
                  color: newStatus
                      ? Colors.redAccent
                      : Colors.green,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _userService
          .setUserSuspended(
        userId: user.uid,
        suspended: newStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'User suspended'
                : 'User restored',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  bool _matchesSearch(
    AppUser user,
  ) {
    if (_searchText.isEmpty) {
      return true;
    }

    final query =
        _searchText.toLowerCase();

    return user.nickname
            .toLowerCase()
            .contains(query) ||
        user.email
            .toLowerCase()
            .contains(query) ||
        user.uid
            .toLowerCase()
            .contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid =
        FirebaseAuth.instance
            .currentUser
            ?.uid;

    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B0B0B),
        elevation: 0,
        title: const Text(
          'Manage Users',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            child: TextField(
              controller:
                  _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText =
                      value.trim();
                });
              },
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration:
                  InputDecoration(
                hintText:
                    'Search nickname or email',
                hintStyle:
                    const TextStyle(
                  color: Colors.white38,
                ),
                prefixIcon:
                    const Icon(
                  Icons.search,
                  color: Colors.white54,
                ),
                suffixIcon:
                    _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();

                              setState(() {
                                _searchText =
                                    '';
                              });
                            },
                            icon:
                                const Icon(
                              Icons.close,
                              color: Colors
                                  .white54,
                            ),
                          )
                        : null,
                filled: true,
                fillColor:
                    const Color(
                  0xFF171717,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    18,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<
                List<AppUser>>(
              stream: _userService
                  .getAllUsersForAdmin(),
              builder:
                  (context, snapshot) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color: Colors
                          .purpleAccent,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(
                        24,
                      ),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                    ),
                  );
                }

                final users =
                    (snapshot.data ??
                            [])
                        .where(
                          _matchesSearch,
                        )
                        .toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(
                        color:
                            Colors.white60,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    0,
                    16,
                    20,
                  ),
                  itemCount:
                      users.length,
                  itemBuilder:
                      (context, index) {
                    final user =
                        users[index];

                    final isMe =
                        user.uid ==
                            currentUid;

                    final firstLetter =
                        user.nickname
                                .trim()
                                .isNotEmpty
                            ? user
                                .nickname
                                .trim()[0]
                                .toUpperCase()
                            : '?';

                    return Container(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),
                      padding:
                          const EdgeInsets
                              .all(
                        14,
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
                          18,
                        ),
                        border:
                            Border.all(
                          color: user
                                  .isSuspended
                              ? Colors
                                  .redAccent
                                  .withValues(
                                    alpha:
                                        0.4,
                                  )
                              : Colors
                                  .white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius:
                                    27,
                                backgroundColor:
                                    Colors
                                        .purpleAccent,
                                child:
                                    Text(
                                  firstLetter,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        21,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (user
                                  .isOnline)
                                Positioned(
                                  right:
                                      0,
                                  bottom:
                                      1,
                                  child:
                                      Container(
                                    width:
                                        13,
                                    height:
                                        13,
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .green,
                                      shape: BoxShape
                                          .circle,
                                      border:
                                          Border.all(
                                        color: const Color(
                                          0xFF171717,
                                        ),
                                        width:
                                            2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child:
                                          Text(
                                        user.nickname
                                                .isEmpty
                                            ? 'No nickname'
                                            : user
                                                .nickname,
                                        maxLines:
                                            1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize:
                                              17,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (user
                                        .isAdmin) ...[
                                      const SizedBox(
                                        width:
                                            6,
                                      ),
                                      const Icon(
                                        Icons
                                            .admin_panel_settings,
                                        color: Colors
                                            .purpleAccent,
                                        size:
                                            18,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  user.email
                                          .isEmpty
                                      ? user
                                          .uid
                                      : user
                                          .email,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white54,
                                    fontSize:
                                        12,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  user.isSuspended
                                      ? 'Suspended'
                                      : user.isOnline
                                          ? 'Online'
                                          : 'Active',
                                  style:
                                      TextStyle(
                                    color: user
                                            .isSuspended
                                        ? Colors
                                            .redAccent
                                        : user
                                                .isOnline
                                            ? Colors.green
                                            : Colors.white38,
                                    fontSize:
                                        12,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isMe &&
                              !user
                                  .isAdmin)
                            PopupMenuButton<
                                String>(
                              icon:
                                  const Icon(
                                Icons
                                    .more_vert,
                                color: Colors
                                    .white70,
                              ),
                              color:
                                  const Color(
                                0xFF242424,
                              ),
                              onSelected:
                                  (value) {
                                if (value ==
                                    'suspend') {
                                  _changeSuspendedStatus(
                                    user,
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                PopupMenuItem<
                                    String>(
                                  value:
                                      'suspend',
                                  child:
                                      Text(
                                    user.isSuspended
                                        ? 'Restore User'
                                        : 'Suspend User',
                                    style:
                                        TextStyle(
                                      color: user
                                              .isSuspended
                                          ? Colors
                                              .green
                                          : Colors
                                              .redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}