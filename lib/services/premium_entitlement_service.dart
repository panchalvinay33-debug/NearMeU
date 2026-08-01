import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.isPremium,
    required this.plan,
    required this.activeSources,
    this.expiresAt,
  });

  final bool isPremium;
  final String plan;
  final List<String> activeSources;
  final DateTime? expiresAt;

  factory PremiumEntitlement.fromMap(Map<dynamic, dynamic> data) {
    final expiresAtMillis = data['expiresAtMillis'];
    final sources = data['activeSources'];
    return PremiumEntitlement(
      isPremium: data['isPremium'] == true,
      plan: data['plan']?.toString() == 'premium' ? 'premium' : 'free',
      activeSources: sources is List
          ? sources.map((value) => value.toString()).toList(growable: false)
          : const <String>[],
      expiresAt: expiresAtMillis is num
          ? DateTime.fromMillisecondsSinceEpoch(expiresAtMillis.toInt())
          : null,
    );
  }

  static const free = PremiumEntitlement(
    isPremium: false,
    plan: 'free',
    activeSources: <String>[],
  );
}

class PremiumEntitlementException implements Exception {
  const PremiumEntitlementException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PremiumEntitlementService {
  PremiumEntitlementService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  PremiumEntitlement? _cached;
  DateTime? _cachedAt;

  static const Duration _cacheLifetime = Duration(seconds: 30);

  Future<HttpsCallableResult<dynamic>> _readCallable() {
    return _functions
        .httpsCallable('getMyPremiumEntitlement')
        .call<dynamic>();
  }

  Future<HttpsCallableResult<dynamic>> _readWithAuthRetry() async {
    try {
      return await _readCallable();
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'unauthenticated') rethrow;

      final user = _auth.currentUser;
      if (user == null) rethrow;

      // Account close/reactivation revokes old refresh tokens. A process that
      // stayed alive can briefly retain an auth session whose callable token is
      // stale even though the UI still has a current user. Force one fresh ID
      // token and retry exactly once.
      await user.getIdToken(true);
      return _readCallable();
    }
  }

  Future<PremiumEntitlement> getCurrent({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheLifetime) {
      return _cached!;
    }

    try {
      final result = await _readWithAuthRetry();
      final data = result.data;
      final entitlement = data is Map
          ? PremiumEntitlement.fromMap(data)
          : PremiumEntitlement.free;
      _cached = entitlement;
      _cachedAt = now;
      return entitlement;
    } on FirebaseFunctionsException catch (error) {
      final message = error.message?.trim();
      throw PremiumEntitlementException(
        message == null || message.isEmpty
            ? 'Could not verify Premium access.'
            : message,
      );
    } on FirebaseAuthException catch (error) {
      final message = error.message?.trim();
      throw PremiumEntitlementException(
        message == null || message.isEmpty
            ? 'Please sign in again to verify Premium access.'
            : message,
      );
    }
  }

  Future<bool> hasPremium({bool forceRefresh = false}) async {
    return (await getCurrent(forceRefresh: forceRefresh)).isPremium;
  }

  Future<void> requirePremium({
    required String feature,
    bool forceRefresh = true,
  }) async {
    final entitlement = await getCurrent(forceRefresh: forceRefresh);
    if (entitlement.isPremium) return;
    throw PremiumEntitlementException(
      'Premium is required to $feature.',
    );
  }

  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }
}
