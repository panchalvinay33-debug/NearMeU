import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget section(String title, String body) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
          "Privacy Policy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Your privacy is our priority.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Last Updated : July 2026",
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 25),

            section(
              "Information We Collect",
              "We collect only the information necessary to provide our services, including your Google account details, nickname, profile information and approximate location.",
            ),

            section(
              "Location",
              "Your location is used only to show nearby users. Your exact location is never displayed publicly.",
            ),

            section(
              "Messages",
              "Private chats are intended only for participating users. We do not publicly display your conversations.",
            ),
            section(
              "Data Security",
              "We use industry-standard security measures to protect your account and personal information. While no system is completely secure, we continuously work to improve security.",
            ),

            section(
              "Account Information",
              "You may update or delete your profile information at any time. Some information may be retained where required by law or for legitimate safety purposes.",
            ),

            section(
              "Third-Party Services",
              "NearMeU uses trusted services such as Google Sign-In and Firebase to provide authentication and secure cloud functionality. These services have their own privacy policies.",
            ),

            section(
              "Children's Privacy",
              "NearMeU is strictly intended for adults aged 18 years or older. We do not knowingly collect information from anyone under 18 years of age.",
            ),

            section(
              "Policy Updates",
              "This Privacy Policy may be updated occasionally. Any significant changes will be reflected within the application.",
            ),

            section(
              "Contact Us",
              "For any questions regarding this Privacy Policy, contact us at:\n\nsupportnearmeu@gmail.com",
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "© 2026 NearMeU Technologies\nAll Rights Reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
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