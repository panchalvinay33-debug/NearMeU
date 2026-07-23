class TelemetryPolicy {
  const TelemetryPolicy._();

  static const bool buildOverride = bool.fromEnvironment(
    'ENABLE_FIREBASE_OBSERVABILITY',
    defaultValue: false,
  );

  static bool shouldCollect({
    required bool isReleaseMode,
    bool? explicitOverride,
  }) {
    return explicitOverride ?? (isReleaseMode || buildOverride);
  }

  static String traceName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final safe = normalized.isEmpty ? 'nearmeu_operation' : normalized;
    return safe.length <= 100 ? safe : safe.substring(0, 100);
  }

  static String eventName(String value) {
    final normalized = traceName(value);
    final prefixed = RegExp(r'^[a-z]').hasMatch(normalized)
        ? normalized
        : 'event_$normalized';
    return prefixed.length <= 40 ? prefixed : prefixed.substring(0, 40);
  }
}
