class TelemetryPolicy {
  const TelemetryPolicy._();

  static const bool buildOverride = bool.fromEnvironment(
    'ENABLE_FIREBASE_OBSERVABILITY',
    defaultValue: false,
  );

  static const Set<String> _sensitiveFragments = <String>{
    'email',
    'message',
    'text',
    'latitude',
    'longitude',
    'location',
    'address',
    'phone',
    'uid',
    'user_id',
    'token',
    'photo',
    'name',
  };

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

  static bool allowsField(String key, Object value) {
    final normalizedKey = key.trim().toLowerCase();
    if (normalizedKey.isEmpty) return false;
    if (_sensitiveFragments.any(normalizedKey.contains)) return false;
    return value is String || value is num;
  }

  static String safeAttributeValue(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 100 ? trimmed : trimmed.substring(0, 100);
  }
}
