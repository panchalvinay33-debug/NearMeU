import 'package:flutter/material.dart';
import 'nickname_screen.dart';

class LookingForScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String gender;

  const LookingForScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.gender,
  });

  @override
  State<LookingForScreen> createState() => _LookingForScreenState();
}

class _LookingForScreenState extends State<LookingForScreen> {
  String selectedLookingFor = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Looking For',
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
              'Who do you want to connect with?',
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
                  lookingCard(
                    icon: Icons.male_rounded,
                    title: 'Men',
                    value: 'Male',
                  ),
                  const SizedBox(height: 18),
                  lookingCard(
                    icon: Icons.female_rounded,
                    title: 'Women',
                    value: 'Female',
                  ),
                  const SizedBox(height: 18),
                  lookingCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Both',
                    value: 'Both',
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selectedLookingFor.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NicknameScreen(
                              uid: widget.uid,
                              email: widget.email,
                              gender: widget.gender,
                              lookingFor: selectedLookingFor,
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
                  'Continue',
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

  Widget lookingCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final selected = selectedLookingFor == value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          selectedLookingFor = value;
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
            color: selected ? Colors.purpleAccent : Colors.grey.shade800,
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
