import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/error_logger.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';

void main() {
  group('ErrorLogger', () {
    setUpAll(() async {
      // Initialize once for all tests
      // This may or may not succeed depending on Firebase availability,
      // but that's okay - logging still works in debug mode
      await ErrorLogger.initialize();
    });

    test('isDebugMode returns true in test environment', () {
      // Flutter tests run in debug mode
      expect(ErrorLogger.isDebugMode, isTrue);
      expect(kDebugMode, isTrue);
    });

    group('logError', () {
      test('logs error without throwing', () {
        final error = Exception('Test error');
        final stack = StackTrace.current;

        // Should not throw, just log to console in debug
        expect(
          () => ErrorLogger.logError(error, stackTrace: stack, reason: 'Test'),
          returnsNormally,
        );
      });

      test('logs error with additional info', () {
        final error = Exception('Test error');

        expect(
          () => ErrorLogger.logError(
            error,
            reason: 'API call failed',
            additionalInfo: {'endpoint': '/api/users', 'method': 'GET'},
          ),
          returnsNormally,
        );
      });

      test('logs fatal error', () {
        final error = Exception('Fatal error');

        expect(
          () => ErrorLogger.logError(
            error,
            fatal: true,
            reason: 'Critical failure',
          ),
          returnsNormally,
        );
      });

      test('logs error without optional parameters', () {
        final error = Exception('Simple error');

        expect(() => ErrorLogger.logError(error), returnsNormally);
      });
    });

    group('logFailure', () {
      test('logs failure without throwing', () {
        const failure = NoInternetFailure();

        expect(() => ErrorLogger.logFailure(failure), returnsNormally);
      });

      test('logs failure with additional info', () {
        const failure = ServerFailure(
          message: 'Internal error',
          statusCode: 500,
        );

        expect(
          () => ErrorLogger.logFailure(
            failure,
            additionalInfo: {'endpoint': '/api/messages'},
          ),
          returnsNormally,
        );
      });

      test('logs different failure types', () {
        const failures = [
          NoInternetFailure(),
          ValidationFailure(message: 'Invalid input'),
          UnauthenticatedFailure(),
          MessageSendFailure(),
          TranslationFailure(),
        ];

        for (final failure in failures) {
          expect(() => ErrorLogger.logFailure(failure), returnsNormally);
        }
      });
    });

    group('logAppException', () {
      test('logs app exception without throwing', () {
        const exception = NoInternetException();

        expect(() => ErrorLogger.logAppException(exception), returnsNormally);
      });

      test('logs app exception with stack trace', () {
        const exception = ServerException(
          message: 'Server error',
          statusCode: 500,
        );
        final stack = StackTrace.current;

        expect(
          () => ErrorLogger.logAppException(exception, stackTrace: stack),
          returnsNormally,
        );
      });

      test('logs app exception with additional info', () {
        const exception = ValidationException(
          message: 'Validation failed',
          fieldErrors: {'email': 'Invalid'},
        );

        expect(
          () => ErrorLogger.logAppException(
            exception,
            additionalInfo: {'userId': '123'},
          ),
          returnsNormally,
        );
      });

      test('logs different exception types', () {
        const exceptions = [
          NoInternetException(),
          UnauthenticatedException(),
          MessageSendFailedException(),
          TranslationException(),
          RateLimitExceededException(),
        ];

        for (final exception in exceptions) {
          expect(() => ErrorLogger.logAppException(exception), returnsNormally);
        }
      });
    });

    group('logEvent', () {
      test('logs event without throwing', () {
        expect(() => ErrorLogger.logEvent('User logged in'), returnsNormally);
      });

      test('logs event with parameters', () {
        expect(
          () => ErrorLogger.logEvent(
            'Message sent',
            parameters: {'conversationId': '123', 'messageType': 'text'},
          ),
          returnsNormally,
        );
      });
    });

    group('setUser', () {
      test('sets user without throwing', () async {
        await expectLater(ErrorLogger.setUser('user123'), completes);
      });

      test('sets user with email', () async {
        await expectLater(
          ErrorLogger.setUser('user123', email: 'user@example.com'),
          completes,
        );
      });

      test('sets user with additional info', () async {
        await expectLater(
          ErrorLogger.setUser(
            'user123',
            email: 'user@example.com',
            additionalInfo: {'name': 'John Doe', 'plan': 'premium'},
          ),
          completes,
        );
      });
    });

    group('clearUser', () {
      test('clears user without throwing', () async {
        // First set a user
        await ErrorLogger.setUser('user123');

        // Then clear
        await expectLater(ErrorLogger.clearUser(), completes);
      });
    });

    group('Integration', () {
      test('can log multiple errors in sequence', () {
        final error1 = Exception('Error 1');
        final error2 = Exception('Error 2');
        const failure = NoInternetFailure();

        expect(() {
          ErrorLogger.logError(error1);
          ErrorLogger.logError(error2);
          ErrorLogger.logFailure(failure);
        }, returnsNormally);
      });

      test('can set user and then log errors', () async {
        await ErrorLogger.setUser('user123', email: 'user@example.com');

        final error = Exception('User-specific error');

        expect(
          () => ErrorLogger.logError(
            error,
            additionalInfo: {'action': 'send_message'},
          ),
          returnsNormally,
        );
      });

      test('complete workflow: set user, log, clear', () async {
        // ErrorLogger is already initialized in setUpAll
        await ErrorLogger.setUser('user123');

        ErrorLogger.logEvent('session_start');

        final error = Exception('Test error');
        ErrorLogger.logError(error, reason: 'Testing');

        const failure = ValidationFailure();
        ErrorLogger.logFailure(failure);

        await ErrorLogger.clearUser();

        // Verify logging still works in debug mode
        expect(ErrorLogger.isDebugMode, isTrue);
      });
    });
  });
}
