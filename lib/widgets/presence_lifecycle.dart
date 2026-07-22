import 'package:flutter/widgets.dart';

import '../services/presence_service.dart';

class PresenceLifecycle extends StatefulWidget {
  const PresenceLifecycle({required this.child, super.key});

  final Widget child;

  @override
  State<PresenceLifecycle> createState() => _PresenceLifecycleState();
}

class _PresenceLifecycleState extends State<PresenceLifecycle>
    with WidgetsBindingObserver {
  final PresenceService _presence = PresenceService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presence.start();
    _presence.updateLifecycle(
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _presence.updateLifecycle(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
