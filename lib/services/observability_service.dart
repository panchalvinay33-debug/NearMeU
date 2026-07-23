import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../observability/telemetry_policy.dart';

class ObservabilityService {
  ObservabilityService._();

  static final ObservabilityService instance = ObservabilityService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;

  FlutterExceptionHandler? _previousFlutterErrorHandler;
  ErrorCallback? _previousPlatformErrorHandler;
  bool _initialized = false;
  bool _handlersInstalled = false;
  bool _collectionEnabled = false;

  bool get collectionEnabled => _collectionEnabled;

  List<NavigatorObserver> get navigatorObservers => _collectionEnabled
      ? <NavigatorObserver>[
          FirebaseAnalyticsObserver(analytics: _analytics),
        ]
      : const <NavigatorObserver>[];

  Future<void> initialize({bool? collectionOverride}) async {
    if (_initialized) return;

    _collectionEnabled = TelemetryPolicy.shouldCollect(
      isReleaseMode: kReleaseMode,
      explicitOverride: collectionOverride,
    );

    try {
      await Future.wait(<Future<void>>[
        _crashlytics.setCrashlyticsCollectionEnabled(_collectionEnabled),
        _analytics.setAnalyticsCollectionEnabled(_collectionEnabled),
        _performance.setPerformanceCollectionEnabled(_collectionEnabled),
      ]);

      if (_collectionEnabled) {
        await _crashlytics.setCustomKey(
          'build_mode',
          kReleaseMode ? 'release' : 'non_release_opt_in',
        );
        await _crashlytics.setCustomKey('telemetry_enabled', true);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Firebase observability initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _initialized = true;
    }
  }

  void installGlobalErrorHandlers() {
    if (_handlersInstalled) return;

    _previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final previous = _previousFlutterErrorHandler;
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }

      if (_collectionEnabled) {
        unawaited(_crashlytics.recordFlutterFatalError(details));
      }
    };

    _previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (_collectionEnabled) {
        unawaited(
          _crashlytics.recordError(
            error,
            stack,
            fatal: true,
            reason: 'uncaught_platform_error',
          ),
        );
        return true;
      }

      final previous = _previousPlatformErrorHandler;
      return previous?.call(error, stack) ?? false;
    };

    _handlersInstalled = true;
  }

  Future<T> trace<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String> attributes = const <String, String>{},
  }) async {
    if (!_collectionEnabled) return operation();

    final trace = _performance.newTrace(TelemetryPolicy.traceName(name));
    for (final entry in attributes.entries) {
      final key = TelemetryPolicy.traceName(entry.key);
      final value = _safeAttributeValue(entry.value);
      trace.putAttribute(key, value);
    }

    await trace.start();
    try {
      return await operation();
    } catch (error, stackTrace) {
      await recordNonFatal(
        error,
        stackTrace,
        reason: 'trace_failed:${TelemetryPolicy.traceName(name)}',
      );
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_collectionEnabled) return;

    final safeParameters = <String, Object>{};
    for (final entry in parameters?.entries ?? const Iterable.empty()) {
      if (_isAllowedParameter(entry.key, entry.value)) {
        safeParameters[TelemetryPolicy.eventName(entry.key)] = entry.value;
      }
    }

    try {
      await _analytics.logEvent(
        name: TelemetryPolicy.eventName(name),
        parameters: safeParameters.isEmpty ? null : safeParameters,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Analytics event logging failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (!_collectionEnabled) return;

    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: false,
        reason: reason == null
            ? 'handled_error'
            : TelemetryPolicy.traceName(reason),
      );
    } catch (recordingError, recordingStack) {
      developer.log(
        'Crashlytics non-fatal recording failed',
        error: recordingError,
        stackTrace: recordingStack,
      );
    }
  }

  String _safeAttributeValue(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 100 ? trimmed : trimmed.substring(0, 100);
  }

  bool _isAllowedParameter(String key, Object value) {
    final normalizedKey = key.toLowerCase();
    const sensitiveFragments = <String>{
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

    if (sensitiveFragments.any(normalizedKey.contains)) return false;
    return value is String || value is num;
  }
}
