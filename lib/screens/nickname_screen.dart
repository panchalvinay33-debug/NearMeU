import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../services/validation_service.dart';
import 'nearby_screen.dart';

class NicknameScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String? gender;
  final String? lookingFor;

  const NicknameScreen({
    super.key,
    required this.uid,
    required this.email,
    this.gender,
    this.lookingFor,
  });

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final UserService _userService = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String selectedGender = widget.gender ?? '';
  late String selectedLookingFor = widget.lookingFor ?? '';
  bool isLoading = false;

  bool get _canContinue {
    try {
      ValidationService.nickname(nicknameController.text);
      ValidationService.ageText(ageController.text);
      return selectedGender.isNotEmpty && selectedLookingFor.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate() || !_canContinue) return;
    final nickname = ValidationService.nickname(nicknameController.text);
    final age = ValidationService.ageText(ageController.text);

    setState(() => isLoading = true);
    try {
      final user = AppUser(
        uid: widget.uid,
        email: widget.email,
        nickname: nickname,
        gender: selectedGender,
        lookingFor: selectedLookingFor,
        createdAt: DateTime.now(),
        age: age,
      );
      await _userService.saveUser(user);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => NearbyScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your profile. Please try again.')),
      );
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    nicknameController.addListener(() => setState(() {}));
    ageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nicknameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Complete Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF111111)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(radius: 42, backgroundColor: Colors.white24, child: Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 34)),
                    SizedBox(height: 16),
                    Text('Build your NearMeU profile', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('Photo upload is coming soon — start with your essentials.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _textField(nicknameController, 'Nickname', TextInputType.text),
              const SizedBox(height: 14),
              _textField(ageController, 'Age', TextInputType.number),
              const SizedBox(height: 24),
              _section('Gender'),
              Wrap(spacing: 10, runSpacing: 10, children: ['Male', 'Female', 'Other'].map((v) => _chip(v, selectedGender == v, () => setState(() => selectedGender = v))).toList()),
              const SizedBox(height: 24),
              _section('Looking For'),
              Wrap(spacing: 10, runSpacing: 10, children: ['Men', 'Women', 'Both'].map((v) => _chip(v, selectedLookingFor == v, () => setState(() => selectedLookingFor = v))).toList()),
              const SizedBox(height: 34),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: isLoading || !_canContinue ? null : _saveUser,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Continue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      );

  Widget _chip(String title, bool selected, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: selected ? Colors.purpleAccent.withValues(alpha: .18) : const Color(0xff171717),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? Colors.purpleAccent : Colors.grey.shade800, width: 2),
          ),
          child: Text(title, style: TextStyle(color: selected ? Colors.purpleAccent : Colors.white, fontWeight: FontWeight.w800)),
        ),
      );

  Widget _textField(TextEditingController controller, String hint, TextInputType type) => TextFormField(
        controller: controller,
        keyboardType: type,
        textInputAction: hint == 'Nickname' ? TextInputAction.next : TextInputAction.done,
        inputFormatters: hint == 'Age' ? [FilteringTextInputFormatter.digitsOnly] : null,
        validator: (value) {
          try {
            hint == 'Age' ? ValidationService.ageText(value ?? '') : ValidationService.nickname(value ?? '');
            return null;
          } on ValidationException catch (e) {
            return e.message;
          }
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xff171717),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      );
}
