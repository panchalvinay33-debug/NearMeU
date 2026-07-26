import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../services/notification_navigation_service.dart';
import '../services/user_service.dart';
import '../services/validation_service.dart';
import 'nearby_screen.dart';

class PremiumSignupScreen extends StatefulWidget {
  const PremiumSignupScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  final String uid;
  final String email;

  @override
  State<PremiumSignupScreen> createState() => _PremiumSignupScreenState();
}

class _PremiumSignupScreenState extends State<PremiumSignupScreen> {
  static const Color _background = Color(0xFF08070C);
  static const Color _surface = Color(0xFF17131F);
  static const Color _primary = Color(0xFFB45CFF);
  static const Color _primaryLight = Color(0xFFE4B8FF);

  final UserService _userService = UserService();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

  int _step = 0;
  String _gender = '';
  String _lookingFor = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _gender.isNotEmpty;
      case 2:
        return _lookingFor.isNotEmpty;
      case 3:
        return !_isSaving;
      default:
        return false;
    }
  }

  String get _buttonLabel {
    if (_step == 0) return 'Get Started';
    if (_step == 3) return 'Create My Profile';
    return 'Continue';
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (!_canContinue) return;

    if (_step < 3) {
      setState(() => _step += 1);
      return;
    }

    if (_profileFormKey.currentState?.validate() != true) return;
    await _saveProfile();
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _saveProfile() async {
    final nickname = ValidationService.nickname(_nicknameController.text);
    final age = ValidationService.ageText(_ageController.text);

    setState(() => _isSaving = true);
    try {
      final user = AppUser(
        uid: widget.uid,
        email: widget.email,
        nickname: nickname,
        gender: _gender,
        lookingFor: _lookingFor,
        createdAt: DateTime.now(),
        age: age,
      );

      await _userService.saveUser(user);
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NearbyScreen()),
        (_) => false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationNavigationService.instance.setAppShellReady(true);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _PremiumBackdrop()),
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(.08, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_step),
                      child: _buildStep(),
                    ),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _isSaving ? null : _goBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'NearMeU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
          ),
          if (_step > 0)
            Text(
              '$_step of 3',
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildGenderStep();
      case 2:
        return _buildLookingForStep();
      case 3:
        return _buildProfileStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 12),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFD071FF), Color(0xFF7B3CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _primary.withValues(alpha: .34),
                  blurRadius: 46,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 72,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 34),
          const Text(
            'Meet people\nclose to you',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              height: 1.04,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Create a private profile, discover people nearby and start meaningful conversations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.55),
          ),
          const SizedBox(height: 34),
          const _FeatureRow(
            icon: Icons.shield_outlined,
            title: 'Private by design',
            subtitle: 'Your exact location is never shown.',
          ),
          const SizedBox(height: 12),
          const _FeatureRow(
            icon: Icons.forum_outlined,
            title: 'Real conversations',
            subtitle: 'Connect with people who are genuinely nearby.',
          ),
          const SizedBox(height: 12),
          const _FeatureRow(
            icon: Icons.favorite_border_rounded,
            title: 'You stay in control',
            subtitle: 'Choose who you want to discover and chat with.',
          ),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return _StepShell(
      eyebrow: 'ABOUT YOU',
      title: 'How do you identify?',
      subtitle: 'Choose the option that best describes you.',
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ChoiceCard(
              icon: Icons.male_rounded,
              label: 'Male',
              selected: _gender == 'Male',
              onTap: () => setState(() => _gender = 'Male'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ChoiceCard(
              icon: Icons.female_rounded,
              label: 'Female',
              selected: _gender == 'Female',
              onTap: () => setState(() => _gender = 'Female'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookingForStep() {
    return _StepShell(
      eyebrow: 'YOUR PREFERENCE',
      title: 'Who would you like to meet?',
      subtitle: 'You can change this later from your profile settings.',
      child: Column(
        children: <Widget>[
          _WideChoiceCard(
            icon: Icons.male_rounded,
            label: 'Male',
            selected: _lookingFor == 'Male',
            onTap: () => setState(() => _lookingFor = 'Male'),
          ),
          const SizedBox(height: 14),
          _WideChoiceCard(
            icon: Icons.female_rounded,
            label: 'Female',
            selected: _lookingFor == 'Female',
            onTap: () => setState(() => _lookingFor = 'Female'),
          ),
          const SizedBox(height: 14),
          _WideChoiceCard(
            icon: Icons.people_alt_rounded,
            label: 'Both',
            selected: _lookingFor == 'Both',
            onTap: () => setState(() => _lookingFor = 'Both'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    return Form(
      key: _profileFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _StepShell(
        eyebrow: 'LAST STEP',
        title: 'Make it yours',
        subtitle: 'Add a nickname and your age to complete your profile.',
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _nicknameController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                try {
                  ValidationService.nickname(value ?? '');
                  return null;
                } on ValidationException catch (error) {
                  return error.message;
                }
              },
              decoration: _fieldDecoration(
                label: 'Nickname',
                hint: 'How should people know you?',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                try {
                  ValidationService.ageText(value ?? '');
                  return null;
                } on ValidationException catch (error) {
                  return error.message;
                }
              },
              decoration: _fieldDecoration(
                label: 'Age',
                hint: 'Enter your age',
                icon: Icons.cake_outlined,
              ),
              onFieldSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.lock_outline_rounded, color: _primaryLight),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your email stays private and is never shown on your public profile.',
                      style: TextStyle(color: Colors.white60, height: 1.4),
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

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _primaryLight),
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: _primaryLight),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .055),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        18 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_step > 0) ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _step / 3,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: .08),
                valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: _canContinue
                    ? const LinearGradient(
                        colors: <Color>[Color(0xFFD36CFF), Color(0xFF7C45FF)],
                      )
                    : const LinearGradient(
                        colors: <Color>[Color(0xFF34313A), Color(0xFF25232A)],
                      ),
                boxShadow: _canContinue
                    ? <BoxShadow>[
                        BoxShadow(
                          color: _primary.withValues(alpha: .22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: ElevatedButton(
                onPressed: _canContinue ? _continue : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            _buttonLabel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 21),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBackdrop extends StatelessWidget {
  const _PremiumBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.7, -.8),
          radius: 1.2,
          colors: <Color>[Color(0xFF28133B), Color(0xFF08070C)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -85,
            top: 100,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B48FF).withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            left: -110,
            bottom: 80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5FC8).withValues(alpha: .055),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: const TextStyle(
              color: _PremiumSignupScreenState._primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 34),
          child,
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: selected
              ? _PremiumSignupScreenState._primary.withValues(alpha: .16)
              : _PremiumSignupScreenState._surface,
          border: Border.all(
            color: selected
                ? _PremiumSignupScreenState._primary
                : Colors.white.withValues(alpha: .08),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: _PremiumSignupScreenState._primary.withValues(
                      alpha: .18,
                    ),
                    blurRadius: 24,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    color: selected
                        ? _PremiumSignupScreenState._primaryLight
                        : Colors.white70,
                    size: 64,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 14,
                right: 14,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: _PremiumSignupScreenState._primary,
                  child: Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WideChoiceCard extends StatelessWidget {
  const _WideChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? _PremiumSignupScreenState._primary.withValues(alpha: .15)
              : _PremiumSignupScreenState._surface,
          border: Border.all(
            color: selected
                ? _PremiumSignupScreenState._primary
                : Colors.white.withValues(alpha: .08),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _PremiumSignupScreenState._primary.withValues(alpha: .22)
                    : Colors.white.withValues(alpha: .06),
              ),
              child: Icon(
                icon,
                color: selected
                    ? _PremiumSignupScreenState._primaryLight
                    : Colors.white70,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _PremiumSignupScreenState._primary
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? _PremiumSignupScreenState._primary
                      : Colors.white24,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _PremiumSignupScreenState._primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: _PremiumSignupScreenState._primaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
