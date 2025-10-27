import 'package:flutter/foundation.dart';

/// Performance monitoring utility for tracking slow operations.
///
/// Usage:
/// ```dart
/// await PerformanceMonitor.track('myOperation', () async {
///   // Your code here
/// });
/// ```
///
/// Automatically logs operations that take longer than threshold.
class PerformanceMonitor {
  /// Tracks execution time of an async operation.
  ///
  /// Logs warning if operation takes longer than [slowThreshold].
  /// Logs info if operation takes longer than [infoThreshold].
  static Future<T> track<T>(
    String operation,
    Future<T> Function() fn, {
    int slowThreshold = 100, // ms
    int infoThreshold = 50, // ms
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await fn();
    } finally {
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;

      if (ms > slowThreshold) {
        debugPrint('⚠️ SLOW: $operation took ${ms}ms');
      } else if (ms > infoThreshold) {
        debugPrint('⏱️ $operation took ${ms}ms');
      }
    }
  }

  /// Tracks execution time of a synchronous operation.
  static T trackSync<T>(
    String operation,
    T Function() fn, {
    int slowThreshold = 16, // ms (one frame)
    int infoThreshold = 8, // ms
  }) {
    final stopwatch = Stopwatch()..start();
    try {
      return fn();
    } finally {
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;

      if (ms > slowThreshold) {
        debugPrint('⚠️ SLOW SYNC: $operation took ${ms}ms (blocking UI!)');
      } else if (ms > infoThreshold) {
        debugPrint('⏱️ SYNC: $operation took ${ms}ms');
      }
    }
  }

  /// Tracks widget build time.
  ///
  /// Use in build() methods to identify slow widget rebuilds:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return PerformanceMonitor.trackBuild(
  ///     'MyWidget',
  ///     () => Container(child: ...),
  ///   );
  /// }
  /// ```
  static T trackBuild<T>(String widgetName, T Function() fn) =>
      trackSync('Build: $widgetName', fn);

  /// Logs a performance marker without tracking.
  ///
  /// Useful for marking points in execution flow.
  static void mark(String message) {
    debugPrint('📍 PERF: $message');
  }
}

/// Extension on Stopwatch for easier performance tracking.
extension StopwatchExt on Stopwatch {
  /// Returns elapsed time in milliseconds with message.
  String toPerformanceString(String operation) {
    final ms = elapsedMilliseconds;
    return '$operation: ${ms}ms';
  }
}
