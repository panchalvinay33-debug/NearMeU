import 'package:flutter/material.dart';

/// App startup wrapper.
///
/// Remote version enforcement is disabled until the production callable
/// function and App Check configuration are deployed and verified. Keeping a
/// broken remote gate here would lock every installed app out of NearMeU.
class AppVersionGate extends StatelessWidget {
  const AppVersionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
