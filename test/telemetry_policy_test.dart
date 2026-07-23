import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/observability/telemetry_policy.dart';

void main() {
  group('TelemetryPolicy.shouldCollect', () {
    test('collects by default in release mode', () {
      expect(
        TelemetryPolicy.shouldCollect(isReleaseMode: true),
        isTrue,
      );
    });

    test('does not collect by default in non-release mode', () {
      expect(
        TelemetryPolicy.shouldCollect(isReleaseMode: false),
        TelemetryPolicy.buildOverride,
      );
    });

    test('explicit override can enable non-release collection', () {
      expect(
        TelemetryPolicy.shouldCollect(
          isReleaseMode: false,
          explicitOverride: true,
        ),
        isTrue,
      );
    });

    test('explicit override can disable release collection', () {
      expect(
        TelemetryPolicy.shouldCollect(
          isReleaseMode: true,
          explicitOverride: false,
        ),
        isFalse,
      );
    });
  });

  group('TelemetryPolicy naming', () {
    test('normalizes a performance trace name', () {
      expect(
        TelemetryPolicy.traceName(' Startup / Nearby Search '),
        'startup_nearby_search',
      );
    });

    test('uses a safe fallback for an empty trace name', () {
      expect(TelemetryPolicy.traceName('---'), 'nearmeu_operation');
    });

    test('bounds trace names to one hundred characters', () {
      expect(TelemetryPolicy.traceName('a' * 150), hasLength(100));
    });

    test('analytics event name starts with a letter', () {
      expect(TelemetryPolicy.eventName('123 opened'), 'event_123_opened');
    });

    test('bounds analytics event names to forty characters', () {
      expect(TelemetryPolicy.eventName('event ${'x' * 100}'), hasLength(40));
    });
  });

  group('TelemetryPolicy privacy', () {
    test('allows low-cardinality operational fields', () {
      expect(TelemetryPolicy.allowsField('result', 'success'), isTrue);
      expect(TelemetryPolicy.allowsField('duration_bucket', 3), isTrue);
    });

    test('rejects sensitive identifiers and content fields', () {
      expect(TelemetryPolicy.allowsField('email', 'a@example.com'), isFalse);
      expect(TelemetryPolicy.allowsField('message_text', 'hello'), isFalse);
      expect(TelemetryPolicy.allowsField('exact_location', 'x'), isFalse);
      expect(TelemetryPolicy.allowsField('firebase_uid', 'secret'), isFalse);
      expect(TelemetryPolicy.allowsField('device_token', 'secret'), isFalse);
    });

    test('rejects unsupported parameter types', () {
      expect(TelemetryPolicy.allowsField('result', true), isFalse);
      expect(TelemetryPolicy.allowsField('result', <String>[]), isFalse);
    });

    test('trims and bounds performance attribute values', () {
      expect(TelemetryPolicy.safeAttributeValue('  success  '), 'success');
      expect(
        TelemetryPolicy.safeAttributeValue('x' * 150),
        hasLength(100),
      );
    });
  });
}
