import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';

/// Centralized error logging service
///
/// Logs errors to Firebase Crashlytics in production
/// and prints to console in debug mode.
///
/// Usage:
/// ```dart
/// try {
///   // Some operation
/// } catch (e, stack) {
///   ErrorLogger.logError(e, stack);
///   // or
///   ErrorLogger.logFailure(someFailure);
/// }
/// ```
class ErrorLogger {
  static FirebaseCrashlytics? _crashlytics;
  static bool _isInitialized = false;

  /// Initialize the error logger
  ///
  /// Should be called at app startup.
  /// In debug mode, Crashlytics collection is disabled.
  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable Crashlytics collection only in release mode
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        logError(
          details.exception,
          stackTrace: details.stack,
          reason: 'Flutter Framework Error',
          fatal: true,
        );
      };

      // Pass all uncaught async errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        logError(
          error,
          stackTrace: stack,
          reason: 'Uncaught Async Error',
          fatal: true,
        );
        return true;
      };

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint(
          '🔍 ErrorLogger: Initialized (Debug mode - no remote logging)',
        );
      }
    } catch (e) {
      debugPrint('❌ ErrorLogger: Failed to initialize: $e');
    }
  }

  /// Log an error/exception
  ///
  /// [error] - The error or exception
  /// [stackTrace] - Optional stack trace
  /// [reason] - Optional reason/context for the error
  /// [fatal] - Whether this error is fatal (default: false)
  /// [additionalInfo] - Optional additional information as key-value pairs
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? additionalInfo,
  }) {
    // Print to console in debug mode
    if (kDebugMode) {
      final prefix = fatal ? '💀' : '❌';
      debugPrint('$prefix Error: $error');
      if (reason != null) {
        debugPrint('  Reason: $reason');
      }
      if (stackTrace != null) {
        debugPrint(
          '  Stack: ${stackTrace.toString().split('\n').take(5).join('\n  ')}',
        );
      }
      if (additionalInfo != null) {
        debugPrint('  Info: $additionalInfo');
      }
    }

    // Log to Crashlytics in release mode
    if (!kDebugMode && _crashlytics != null) {
      try {
        // Set custom keys for additional context
        if (additionalInfo != null) {
          additionalInfo.forEach((key, value) {
            _crashlytics!.setCustomKey(key, value.toString());
          });
        }

        if (reason != null) {
          _crashlytics!.setCustomKey('error_reason', reason);
        }

        // Record the error
        if (fatal) {
          _crashlytics!.recordError(
            error,
            stackTrace,
            reason: reason ?? 'Fatal Error',
            fatal: true,
          );
        } else {
          _crashlytics!.recordError(error, stackTrace, reason: reason);
        }
      } catch (e) {
        debugPrint('Failed to log error to Crashlytics: $e');
      }
    }
  }

  /// Log a [Failure]
  ///
  /// [failure] - The failure to log
  /// [additionalInfo] - Optional additional information
  static void logFailure(
    Failure failure, {
    Map<String, dynamic>? additionalInfo,
  }) {
    final info = {
      'failure_type': failure.runtimeType.toString(),
      'failure_code': failure.code ?? 'none',
      'failure_message': failure.message,
      ...?additionalInfo,
    };

    logError(
      failure,
      stackTrace: StackTrace.current,
      reason: 'Business Logic Failure',
      additionalInfo: info,
    );
  }

  /// Log an [AppException]
  ///
  /// [exception] - The exception to log
  /// [stackTrace] - Optional stack trace
  /// [additionalInfo] - Optional additional information
  static void logAppException(
    AppException exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) {
    final info = {
      'exception_type': exception.runtimeType.toString(),
      'exception_code': exception.code ?? 'none',
      ...?additionalInfo,
    };

    logError(
      exception,
      stackTrace: stackTrace ?? StackTrace.current,
      reason: 'Application Exception',
      additionalInfo: info,
    );
  }

  /// Log a custom event (non-error)
  ///
  /// Useful for tracking important events that aren't errors.
  /// Only logged in release mode.
  ///
  /// [event] - Event name/description
  /// [parameters] - Optional event parameters
  static void logEvent(String event, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      debugPrint('📊 Event: $event ${parameters ?? ''}');
      return;
    }

    if (_crashlytics != null) {
      try {
        _crashlytics!.log('Event: $event');
        if (parameters != null) {
          parameters.forEach((key, value) {
            _crashlytics!.setCustomKey(key, value.toString());
          });
        }
      } catch (e) {
        debugPrint('Failed to log event to Crashlytics: $e');
      }
    }
  }

  /// Set user identifier for error tracking
  ///
  /// [userId] - The user ID
  /// [email] - Optional user email
  /// [additionalInfo] - Optional additional user info
  static Future<void> setUser(
    String userId, {
    String? email,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (kDebugMode) {
      debugPrint('👤 User set: $userId ${email != null ? '($email)' : ''}');
    }

    if (_crashlytics != null) {
      try {
        await _crashlytics!.setUserIdentifier(userId);

        if (email != null) {
          unawaited(_crashlytics!.setCustomKey('user_email', email));
        }

        if (additionalInfo != null) {
          additionalInfo.forEach((key, value) {
            unawaited(
              _crashlytics!.setCustomKey('user_$key', value.toString()),
            );
          });
        }
      } catch (e) {
        debugPrint('Failed to set user in Crashlytics: $e');
      }
    }
  }

  /// Clear user identifier (on logout)
  static Future<void> clearUser() async {
    if (kDebugMode) {
      debugPrint('👤 User cleared');
    }

    if (_crashlytics != null) {
      try {
        await _crashlytics!.setUserIdentifier('');
        unawaited(_crashlytics!.setCustomKey('user_email', ''));
      } catch (e) {
        debugPrint('Failed to clear user in Crashlytics: $e');
      }
    }
  }

  /// Check if error logging is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if running in debug mode (no remote logging)
  static bool get isDebugMode => kDebugMode;
}
