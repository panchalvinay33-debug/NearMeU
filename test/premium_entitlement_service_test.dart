import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/services/premium_entitlement_service.dart';

void main() {
  test('free entitlement parses safely', () {
    final entitlement = PremiumEntitlement.fromMap(<String, dynamic>{
      'plan': 'free',
      'isPremium': false,
      'activeSources': <String>[],
      'expiresAtMillis': null,
    });

    expect(entitlement.isPremium, isFalse);
    expect(entitlement.plan, 'free');
    expect(entitlement.activeSources, isEmpty);
    expect(entitlement.expiresAt, isNull);
  });

  test('premium entitlement preserves source and expiry', () {
    final entitlement = PremiumEntitlement.fromMap(<String, dynamic>{
      'plan': 'premium',
      'isPremium': true,
      'activeSources': <String>['googlePlay'],
      'expiresAtMillis': 2000,
    });

    expect(entitlement.isPremium, isTrue);
    expect(entitlement.plan, 'premium');
    expect(entitlement.activeSources, <String>['googlePlay']);
    expect(entitlement.expiresAt?.millisecondsSinceEpoch, 2000);
  });

  test('unexpected plan cannot locally forge Premium', () {
    final entitlement = PremiumEntitlement.fromMap(<String, dynamic>{
      'plan': 'premium-plus',
      'isPremium': false,
      'activeSources': <String>['local'],
    });

    expect(entitlement.isPremium, isFalse);
    expect(entitlement.plan, 'free');
  });
}
