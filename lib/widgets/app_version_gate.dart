import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_version_service.dart';

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  final AppVersionService _service = AppVersionService();
  AppVersionPolicy? _policy;
  Object? _error;
  bool _loading = kReleaseMode;
  bool _openingUpdate = false;

  @override
  void initState() {
    super.initState();
    if (kReleaseMode) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final policy = await _service.fetchPolicy();
      if (!mounted) return;
      setState(() {
        _policy = policy;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openUpdate() async {
    final policy = _policy;
    if (policy == null || policy.updateUrl.isEmpty || _openingUpdate) return;
    setState(() => _openingUpdate = true);
    try {
      final uri = Uri.tryParse(policy.updateUrl);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open the update link.');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not open the update link. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _openingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug/profile builds are for local testing. They must not be blocked by
    // App Check or remote version-policy failures. Production release builds
    // still enforce the server-backed version gate.
    if (!kReleaseMode) return widget.child;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xff0B0B0B),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _policy == null) {
      return _BlockingMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to verify this app version',
        message:
            'Connect to the internet and try again. NearMeU must verify that this version is supported before opening.',
        buttonLabel: 'Retry',
        onPressed: _load,
      );
    }

    final policy = _policy!;
    if (policy.maintenanceMode) {
      return _BlockingMessage(
        icon: Icons.engineering_rounded,
        title: 'NearMeU is under maintenance',
        message: policy.message,
        buttonLabel: 'Check again',
        onPressed: _load,
      );
    }

    if (policy.updateRequired) {
      return PopScope(
        canPop: false,
        child: _BlockingMessage(
          icon: Icons.system_update_rounded,
          title: 'Update NearMeU to continue',
          message:
              '${policy.message}\n\nInstalled: ${policy.installedVersionName} (${policy.installedVersionCode})\nRequired: ${policy.latestVersionName} (${policy.minimumSupportedVersionCode})',
          buttonLabel:
              _openingUpdate ? 'Opening update…' : 'Update latest version',
          onPressed:
              policy.updateUrl.isEmpty || _openingUpdate ? null : _openUpdate,
          secondaryLabel: 'I updated the app',
          onSecondaryPressed: _load,
        ),
      );
    }

    return widget.child;
  }
}

class _BlockingMessage extends StatelessWidget {
  const _BlockingMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0B0B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 76, color: Colors.purpleAccent),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(buttonLabel),
                  ),
                ),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
