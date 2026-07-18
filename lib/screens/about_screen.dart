import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        centerTitle: true,
        title: const Text(
          'About NearMeU',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            const SizedBox(height: 10),

            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "NearMeU",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Version 1.0.0",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "About NearMeU",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 15),

                    Text(
                      "NearMeU is a privacy-first platform designed to help adults discover and connect with nearby people in a safe, secure and respectful environment.",
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.6,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Features",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    SizedBox(height: 15),

                    ListTile(
                      leading: Icon(Icons.lock,color: Colors.deepPurple),
                      title: Text(
                        "Privacy First",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    ListTile(
                      leading: Icon(Icons.location_on,color: Colors.deepPurple),
                      title: Text(
                        "Nearby Discovery",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    ListTile(
                      leading: Icon(Icons.chat,color: Colors.deepPurple),
                      title: Text(
                        "Secure Chat",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.shield,color: Colors.deepPurple),
                      title: Text(
                        "Safe Community",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    ListTile(
                      leading: Icon(Icons.flash_on,color: Colors.deepPurple),
                      title: Text(
                        "Fast & Lightweight",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Support",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 15),

                    Row(
                      children: [

                        Icon(
                          Icons.email,
                          color: Colors.deepPurple,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            "supportnearmeu@gmail.com",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Made with ❤️ in India",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "© 2026 NearMeU Technologies\nAll Rights Reserved.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }
}