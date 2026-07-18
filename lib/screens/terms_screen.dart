import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        backgroundColor: const Color(0xFF1E1E1E),
        centerTitle: true,
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Terms & Conditions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Effective: July 2026",
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 25),

            section(
              "Eligibility",
              "NearMeU is available only for users who are 18 years of age or older. By using this application, you confirm that you meet this requirement.",
            ),

            section(
              "User Responsibility",
              "You are responsible for all activity performed using your account and for maintaining accurate profile information.",
            ),

            section(
              "Respectful Behaviour",
              "Users must treat others respectfully. Harassment, threats, hate speech, bullying or abusive behaviour will not be tolerated.",
            ),
            section(
              "Prohibited Activities",
              "Fake profiles, impersonation, scams, spam, illegal activities, sharing harmful content or violating applicable laws are strictly prohibited.",
            ),

            section(
              "Account Suspension",
              "NearMeU reserves the right to suspend or permanently remove any account that violates these Terms or poses a risk to the community.",
            ),

            section(
              "Privacy",
              "Your use of NearMeU is also governed by our Privacy Policy. Please read it carefully before using the application.",
            ),

            section(
              "Limitation of Liability",
              "NearMeU provides the platform 'as is'. We are not responsible for the actions, conversations or behaviour of individual users on the platform.",
            ),

            section(
              "Changes to Terms",
              "We may update these Terms & Conditions from time to time. Continued use of the application after changes means you accept the updated Terms.",
            ),

            section(
              "Contact Us",
              "If you have any questions regarding these Terms & Conditions, please contact us:\n\nsupportnearmeu@gmail.com",
            ),

            const SizedBox(height: 30),

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