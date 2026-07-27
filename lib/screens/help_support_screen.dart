import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = 'supportnearmeu@gmail.com';

  Future<void> _openSupportEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: const {
        'subject': 'NearMeU Support Request',
      },
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No email app was found. Please email supportnearmeu@gmail.com manually.',
          ),
        ),
      );
    }
  }

  Widget faq(String question, String answer) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        iconColor: Colors.deepPurple,
        collapsedIconColor: Colors.deepPurple,
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ],
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
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            faq(
              'How do I edit my profile?',
              'Open Profile → Edit Profile and update your information.',
            ),
            faq(
              'How can I change my nickname?',
              'Go to Edit Profile and update your nickname anytime.',
            ),
            faq(
              'How do I block someone?',
              "Open the user's profile and tap the Block option.",
            ),
            faq(
              'How do nearby users work?',
              'NearMeU uses your approximate location to show people near you.',
            ),
            faq(
              'Can I delete my account?',
              'Yes. Contact support or use the delete account option if available in your app version.',
            ),
            faq(
              'Is my personal information safe?',
              'Yes. NearMeU is designed with privacy in mind. Your exact location is never shown publicly, and we use secure authentication and cloud services.',
            ),
            faq(
              'How do I report a user?',
              "Open the user's profile or chat and use the Report option. Our team reviews reports as quickly as possible.",
            ),
            const SizedBox(height: 25),
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openSupportEmail(context),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.deepPurple),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _supportEmail,
                              style: TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.deepPurpleAccent,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to open your email app.',
                        style: TextStyle(color: Colors.white54),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'We usually respond within 24–48 hours.',
                        style: TextStyle(color: Colors.white70, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Thank you for using NearMeU ❤️',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '© 2026 NearMeU Technologies\nAll Rights Reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
