import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../services/validation_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? selectedGender;
  String? selectedLookingFor;

  bool isLoading = true;
  bool isSaving = false;

  final List<String> genderOptions = [
    'Male',
    'Female',
    'Other',
  ];

  final List<String> lookingForOptions = [
    'Male',
    'Female',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final AppUser? user = await _userService.getUser(currentUser!.uid);

    if (!mounted) return;

    if (user != null) {
      _nicknameController.text = user.nickname;

      selectedGender = _userService.normalizeGender(user.gender).isNotEmpty
          ? _userService.normalizeGender(user.gender)
          : null;

      selectedLookingFor =
      _userService.normalizeLookingFor(user.lookingFor).isNotEmpty
          ? _userService.normalizeLookingFor(user.lookingFor)
          : null;

      if (user.age != null) {
        _ageController.text = user.age.toString();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final ageText = _ageController.text.trim();

    if (nickname.isEmpty) {
      _showSnack('Please enter nickname');
      return;
    }

    if (selectedGender == null || selectedGender!.isEmpty) {
      _showSnack('Please select gender');
      return;
    }

    if (selectedLookingFor == null || selectedLookingFor!.isEmpty) {
      _showSnack('Please select looking for');
      return;
    }

    if (ageText.isEmpty) {
      _showSnack('Please enter age');
      return;
    }

    final int? age = int.tryParse(ageText);
    if (age == null) {
      _showSnack('Please enter valid age');
      return;
    }

    try {
      ValidationService.age(age);
    } on ValidationException catch (e) {
      _showSnack(e.message);
      return;
    }

    if (currentUser == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _userService.updateUserProfile(
        uid: currentUser!.uid,
        nickname: nickname,
        gender: selectedGender!,
        lookingFor: selectedLookingFor!,
        age: age,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully ✨'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xff0B0B0B),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.purpleAccent,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff171717),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nicknameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nickname',
                      labelStyle:
                      const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xff111111),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Age',
                      labelStyle:
                      const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xff111111),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    dropdownColor: const Color(0xff171717),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      labelStyle:
                      const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xff111111),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: genderOptions.map((gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedLookingFor,
                    dropdownColor: const Color(0xff171717),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Looking For',
                      labelStyle:
                      const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xff111111),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: lookingForOptions.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLookingFor = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
                    : const Text(
                  'Save Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}