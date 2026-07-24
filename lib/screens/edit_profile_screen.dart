import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../services/profile_photo_service.dart';
import '../services/user_service.dart';
import '../services/validation_service.dart';
import '../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final ProfilePhotoService _profilePhotoService = ProfilePhotoService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedGender;
  String? selectedLookingFor;
  String? _photoUrl;

  bool isLoading = true;
  bool isSaving = false;
  bool _isPhotoBusy = false;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> lookingForOptions = ['Male', 'Female', 'Both'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (currentUser == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final AppUser? user = await _userService.getUser(currentUser!.uid);
    if (!mounted) return;

    if (user != null) {
      _nicknameController.text = user.nickname;
      _photoUrl = user.photoUrl;
      selectedGender = _userService.normalizeGender(user.gender).isNotEmpty
          ? _userService.normalizeGender(user.gender)
          : null;
      selectedLookingFor =
          _userService.normalizeLookingFor(user.lookingFor).isNotEmpty
          ? _userService.normalizeLookingFor(user.lookingFor)
          : null;
      if (user.age != null) _ageController.text = user.age.toString();
    }

    setState(() => isLoading = false);
  }

  Future<void> _changeProfilePhoto() async {
    final uid = currentUser?.uid;
    if (uid == null || _isPhotoBusy) return;

    setState(() => _isPhotoBusy = true);
    try {
      final photoUrl = await _profilePhotoService.pickAndUpload(uid);
      if (!mounted || photoUrl == null) return;
      setState(() => _photoUrl = photoUrl);
      _showSnack('Profile photo updated ✨');
    } on ProfilePhotoException catch (error) {
      if (mounted) _showSnack(error.message);
    } catch (_) {
      if (mounted) {
        _showSnack('Could not upload the profile photo. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _isPhotoBusy = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final uid = currentUser?.uid;
    if (uid == null || _isPhotoBusy || _photoUrl?.isNotEmpty != true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Remove profile photo?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your premium initials avatar will be shown instead.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isPhotoBusy = true);
    try {
      await _profilePhotoService.remove(uid);
      if (!mounted) return;
      setState(() => _photoUrl = null);
      _showSnack('Profile photo removed');
    } catch (_) {
      if (mounted) _showSnack('Could not remove the profile photo.');
    } finally {
      if (mounted) setState(() => _isPhotoBusy = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final nickname = ValidationService.nickname(_nicknameController.text);
    if (selectedGender == null || selectedGender!.isEmpty) {
      _showSnack('Please select gender');
      return;
    }
    if (selectedLookingFor == null || selectedLookingFor!.isEmpty) {
      _showSnack('Please select looking for');
      return;
    }

    final age = ValidationService.ageText(_ageController.text);
    if (currentUser == null) return;

    setState(() => isSaving = true);
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
        const SnackBar(content: Text('Profile updated successfully ✨')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _showSnack('Could not update your profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _photoFallback() {
    final nickname = _nicknameController.text.trim();
    final letter = nickname.isEmpty ? '?' : nickname[0].toUpperCase();
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 46,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasPhoto = _photoUrl?.trim().isNotEmpty == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24143B), Color(0xFF151821)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? Image.network(
                          _photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoFallback(),
                        )
                      : _photoFallback(),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                  ),
                  child: _isPhotoBusy
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Profile photo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Choose a clear photo. NearMeU compresses it before upload.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isPhotoBusy ? null : _changeProfilePhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasPhoto ? 'Change photo' : 'Add photo'),
                ),
              ),
              if (hasPhoto) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Remove profile photo',
                  onPressed: _isPhotoBusy ? null : _removeProfilePhoto,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff171717),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nicknameController,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              try {
                                ValidationService.nickname(value ?? '');
                                return null;
                              } on ValidationException catch (error) {
                                return error.message;
                              }
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Nickname'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              try {
                                ValidationService.ageText(value ?? '');
                                return null;
                              } on ValidationException catch (error) {
                                return error.message;
                              }
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Age'),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            dropdownColor: const Color(0xff171717),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Gender'),
                            items: genderOptions
                                .map(
                                  (gender) => DropdownMenuItem<String>(
                                    value: gender,
                                    child: Text(gender),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedGender = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedLookingFor,
                            dropdownColor: const Color(0xff171717),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Looking For'),
                            items: lookingForOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedLookingFor = value);
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
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xff111111),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
