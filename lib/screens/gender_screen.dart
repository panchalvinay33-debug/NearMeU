import 'package:flutter/material.dart';
import 'looking_for_screen.dart';

class GenderScreen extends StatefulWidget {
  final String uid;
  final String email;

  const GenderScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String selectedGender = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Select Gender",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Choose your gender to continue",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 35),

            Expanded(
              child: Column(
                children: [
                  genderCard(
                    icon: Icons.male_rounded,
                    title: "Male",
                    value: "Male",
                  ),
                  const SizedBox(height: 18),
                  genderCard(
                    icon: Icons.female_rounded,
                    title: "Female",
                    value: "Female",
                  ),
                  const SizedBox(height: 18),
                  genderCard(
                    icon: Icons.transgender_rounded,
                    title: "Other",
                    value: "Other",
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selectedGender.isEmpty
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LookingForScreen(
                        uid: widget.uid,
                        email: widget.email,
                        gender: selectedGender,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget genderCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final bool selected = selectedGender == value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          selectedGender = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected
              ? Colors.purpleAccent.withValues(alpha: .15)
              : const Color(0xff171717),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.purpleAccent
                : Colors.grey.shade800,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.purpleAccent : Colors.white,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.purpleAccent : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}