import 'package:flutter/material.dart';

import '../services/profile_sharing_service.dart';
import '../theme/app_colors.dart';

class ProfileSharingScreen extends StatefulWidget {
  const ProfileSharingScreen({super.key});

  @override
  State<ProfileSharingScreen> createState() => _ProfileSharingScreenState();
}

class _ProfileSharingScreenState extends State<ProfileSharingScreen> {
  final ProfileSharingService _service = ProfileSharingService.instance;

  ProfileShareLink? _link;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final link = await _service.getMyShareLink();
      if (!mounted) return;
      setState(() {
        _link = link;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load profile sharing right now.';
        _loading = false;
      });
    }
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      final link = await _service.setSharingEnabled(enabled);
      if (!mounted) return;
      setState(() {
        _link = link;
        _actionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Profile sharing enabled' : 'Profile sharing disabled',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile sharing.')),
      );
    }
  }

  Future<void> _share() async {
    final link = _link;
    if (link == null || _actionLoading) return;
    try {
      await _service.shareProfileLink(link);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the Android share sheet.')),
      );
    }
  }

  Future<void> _resetLink() async {
    final current = _link;
    if (_actionLoading || current == null || current.url.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset profile link?'),
        content: Text(
          current.enabled
              ? 'Your current shared link will stop working immediately. A new public identifier will be created and sharing will stay ON.'
              : 'Your old link will be replaced with a new public identifier. Sharing will stay OFF until you enable it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset link'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      final link = await _service.rotateShareLink();
      if (!mounted) return;
      setState(() {
        _link = link;
        _actionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New profile link created. Old link revoked.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reset profile link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Profile Sharing'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final link = _link!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      link.enabled ? 'Sharing is ON' : 'Sharing is OFF',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Switch(
                    value: link.enabled,
                    onChanged: _actionLoading ? null : _setEnabled,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Sharing starts only when you turn it ON. Your link uses a revocable public identifier and never contains your Firebase UID, verified email, phone number or exact location.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              if (link.url.isNotEmpty) ...[
                const SizedBox(height: 18),
                SelectableText(
                  link.url,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: link.enabled && !_actionLoading ? _share : null,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share My Profile'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: link.url.isNotEmpty && !_actionLoading ? _resetLink : null,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset Shared Link'),
        ),
        const SizedBox(height: 22),
        const Text(
          'If you disable sharing or reset the link, old links stop resolving. Resetting never turns sharing ON by itself. Blocks, suspension and account availability are checked again whenever a signed-in user opens a shared profile.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      ],
    );
  }
}
