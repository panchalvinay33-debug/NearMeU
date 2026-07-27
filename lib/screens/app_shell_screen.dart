import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/unread_nav_icon.dart';
import 'chats_screen.dart';
import 'nearby_screen.dart';
import 'settings_screen.dart';

/// Keeps the primary authenticated tabs alive. The shell navigation bar is
/// painted over the legacy per-screen bar, avoiding a second layout row while
/// the screens are migrated incrementally.
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late int _currentIndex;

  final List<Widget> _tabs = const <Widget>[
    NearbyScreen(),
    ChatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _tabs),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 12,
              color: AppColors.surface,
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  backgroundColor: AppColors.surface,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: Colors.white54,
                  type: BottomNavigationBarType.fixed,
                  onTap: (index) {
                    if (index == _currentIndex) return;
                    setState(() => _currentIndex = index);
                  },
                  items: <BottomNavigationBarItem>[
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.location_on_rounded),
                      label: 'Nearby',
                    ),
                    BottomNavigationBarItem(
                      icon: uid.isEmpty
                          ? const Icon(Icons.chat_bubble_outline_rounded)
                          : UnreadNavIcon(
                              userId: uid,
                              icon: Icons.chat_bubble_outline_rounded,
                            ),
                      label: 'Chats',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
