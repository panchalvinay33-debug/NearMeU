import 'package:flutter/material.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  Widget section({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.deepPurple,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Community Guidelines",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Help us keep NearMeU safe for everyone.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            section(
              icon: Icons.favorite,
              title: "Respect Everyone",
              body:
                  "Treat every member with kindness and respect regardless of identity, orientation or background.",
            ),

            section(
              icon: Icons.verified_user,
              title: "Be Genuine",
              body:
                  "Use your own identity. Fake accounts, impersonation and misleading profiles are not allowed.",
            ),

            section(
              icon: Icons.pan_tool_alt,
              title: "Consent Matters",
              body:
                  "Respect personal boundaries. If someone is not interested, do not pressure or repeatedly contact them.",
            ),
            section(
              icon: Icons.block,
              title: "No Harassment",
              body:
                  "Harassment, bullying, hate speech, threats, discrimination or abusive language will not be tolerated on NearMeU.",
            ),

            section(
              icon: Icons.report,
              title: "Report Problems",
              body:
                  "If you notice fake profiles, scams, inappropriate behaviour or suspicious activity, report the user immediately through the app.",
            ),

            section(
              icon: Icons.lock,
              title: "Protect Your Privacy",
              body:
                  "Never share passwords, OTPs, bank details or other sensitive personal information with anyone on the platform.",
            ),

            section(
              icon: Icons.gpp_good,
              title: "Follow the Law",
              body:
                  "Do not use NearMeU for illegal activities or to share content that violates local laws or regulations.",
            ),

            section(
              icon: Icons.email,
              title: "Need Help?",
              body:
                  "For questions or to report serious violations, contact us at:\n\nsupportnearmeu@gmail.com",
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "Together we can build a safe,\nrespectful and welcoming community ❤️",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                "© 2026 NearMeU Technologies\nAll Rights Reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }
}