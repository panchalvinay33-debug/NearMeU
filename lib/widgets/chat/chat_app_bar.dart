import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String lastSeen;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const ChatAppBar({
    super.key,
    required this.userName,
    required this.lastSeen,
    this.onBack,
    this.onMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: const Color(0xff0B0B0B),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: 12,
      title: Row(
        children: [

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onBack ?? () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xff171717),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Stack(
            children: [

              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple,
                child: Text(
                  userName.isEmpty
                      ? "?"
                      : userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xff0B0B0B),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Text(
                  userName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  lastSeen,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onMenu,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xff171717),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}