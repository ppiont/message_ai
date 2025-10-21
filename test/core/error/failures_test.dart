import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';

void main() {
  group('Network Failures', () {
    test('NoInternetFailure has correct properties', () {
      const failure = NoInternetFailure();

      expect(
        failure.message,
        'No internet connection. Please check your network settings.',
      );
      expect(failure.code, 'NO_INTERNET');
    });

    test('NetworkTimeoutFailure has correct properties', () {
      const failure = NetworkTimeoutFailure();

      expect(
        failure.message,
        'Request timed out. Please check your connection and try again.',
      );
      expect(failure.code, 'NETWORK_TIMEOUT');
    });

    test('ServerFailure with default message', () {
      const failure = ServerFailure();

      expect(failure.message, 'Server error occurred. Please try again later.');
      expect(failure.statusCode, isNull);
    });

    test('ServerFailure with custom properties', () {
      const failure = ServerFailure(
        message: 'Internal server error',
        code: 'SERVER_ERROR',
        statusCode: 500,
      );

      expect(failure.message, 'Internal server error');
      expect(failure.code, 'SERVER_ERROR');
      expect(failure.statusCode, 500);
    });

    test('ServerFailure equality', () {
      const failure1 = ServerFailure(statusCode: 500);
      const failure2 = ServerFailure(statusCode: 500);
      const failure3 = ServerFailure(statusCode: 404);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });
  });

  group('Authentication Failures', () {
    test('UnauthenticatedFailure has correct properties', () {
      const failure = UnauthenticatedFailure();

      expect(failure.message, 'You must be signed in to perform this action.');
      expect(failure.code, 'UNAUTHENTICATED');
    });

    test('UnauthorizedFailure with default message', () {
      const failure = UnauthorizedFailure();

      expect(
        failure.message,
        'You do not have permission to perform this action.',
      );
      expect(failure.code, 'UNAUTHORIZED');
    });

    test('UnauthorizedFailure with custom message', () {
      const failure = UnauthorizedFailure(message: 'Admin only');

      expect(failure.message, 'Admin only');
    });

    test('EmailAlreadyInUseFailure has correct properties', () {
      const failure = EmailAlreadyInUseFailure();

      expect(
        failure.message,
        'This email address is already in use. Please try another.',
      );
      expect(failure.code, 'EMAIL_ALREADY_IN_USE');
    });

    test('InvalidCredentialsFailure has correct properties', () {
      const failure = InvalidCredentialsFailure();

      expect(failure.message, 'Invalid email or password. Please try again.');
      expect(failure.code, 'INVALID_CREDENTIALS');
    });

    test('UserDisabledFailure has correct properties', () {
      const failure = UserDisabledFailure();

      expect(
        failure.message,
        'This account has been disabled. Please contact support for assistance.',
      );
      expect(failure.code, 'USER_DISABLED');
    });
  });

  group('Database Failures', () {
    test('DatabaseFailure with default message', () {
      const failure = DatabaseFailure();

      expect(failure.message, 'Database error occurred');
    });

    test('DatabaseFailure with custom message', () {
      const failure = DatabaseFailure(
        message: 'Connection lost',
        code: 'DB_CONNECTION_ERROR',
      );

      expect(failure.message, 'Connection lost');
      expect(failure.code, 'DB_CONNECTION_ERROR');
    });

    test('RecordNotFoundFailure with default message', () {
      const failure = RecordNotFoundFailure(recordType: 'User');

      expect(failure.message, 'The requested User was not found.');
      expect(failure.code, 'RECORD_NOT_FOUND');
      expect(failure.recordType, 'User');
    });

    test('RecordNotFoundFailure with custom message', () {
      const failure = RecordNotFoundFailure(
        recordType: 'Message',
        message: 'Message does not exist',
      );

      expect(failure.message, 'Message does not exist');
      expect(failure.recordType, 'Message');
    });

    test('RecordNotFoundFailure equality', () {
      const failure1 = RecordNotFoundFailure(recordType: 'User');
      const failure2 = RecordNotFoundFailure(recordType: 'User');
      const failure3 = RecordNotFoundFailure(recordType: 'Message');

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });

    test('ConstraintViolationFailure has correct properties', () {
      const failure = ConstraintViolationFailure();

      expect(failure.message, 'This operation violates a database constraint.');
      expect(failure.code, 'CONSTRAINT_VIOLATION');
    });
  });

  group('Validation Failures', () {
    test('ValidationFailure with default message', () {
      const failure = ValidationFailure();

      expect(failure.message, 'Please correct the errors and try again.');
      expect(failure.code, 'VALIDATION_ERROR');
      expect(failure.fieldErrors, isNull);
    });

    test('ValidationFailure with field errors', () {
      final fieldErrors = {'email': 'Invalid format', 'password': 'Too short'};
      final failure = ValidationFailure(
        message: 'Form has errors',
        fieldErrors: fieldErrors,
      );

      expect(failure.message, 'Form has errors');
      expect(failure.fieldErrors, fieldErrors);
    });

    test('ValidationFailure getFieldError returns correct error', () {
      final failure = ValidationFailure(
        fieldErrors: {'email': 'Invalid format'},
      );

      expect(failure.getFieldError('email'), 'Invalid format');
      expect(failure.getFieldError('password'), isNull);
    });

    test('ValidationFailure hasFieldError checks correctly', () {
      final failure = ValidationFailure(
        fieldErrors: {'email': 'Invalid format'},
      );

      expect(failure.hasFieldError('email'), isTrue);
      expect(failure.hasFieldError('password'), isFalse);
    });

    test('ValidationFailure with null fieldErrors', () {
      const failure = ValidationFailure();

      expect(failure.hasFieldError('email'), isFalse);
      expect(failure.getFieldError('email'), isNull);
    });

    test('InvalidFormatFailure with default message', () {
      const failure = InvalidFormatFailure(fieldName: 'phoneNumber');

      expect(failure.message, 'Invalid format for phoneNumber.');
      expect(failure.code, 'INVALID_FORMAT');
      expect(failure.fieldName, 'phoneNumber');
    });

    test('InvalidFormatFailure with custom message', () {
      const failure = InvalidFormatFailure(
        fieldName: 'email',
        message: 'Email must contain @',
      );

      expect(failure.message, 'Email must contain @');
      expect(failure.fieldName, 'email');
    });
  });

  group('Storage Failures', () {
    test('FileUploadFailure has correct properties', () {
      const failure = FileUploadFailure();

      expect(failure.message, 'Failed to upload file. Please try again.');
      expect(failure.code, 'FILE_UPLOAD_ERROR');
    });

    test('FileDownloadFailure has correct properties', () {
      const failure = FileDownloadFailure();

      expect(failure.message, 'Failed to download file. Please try again.');
      expect(failure.code, 'FILE_DOWNLOAD_ERROR');
    });

    test('StorageQuotaExceededFailure has correct properties', () {
      const failure = StorageQuotaExceededFailure();

      expect(
        failure.message,
        'Storage quota exceeded. Please free up some space.',
      );
      expect(failure.code, 'STORAGE_QUOTA_EXCEEDED');
    });
  });

  group('Messaging Failures', () {
    test('MessageFailure with default message', () {
      const failure = MessageFailure();

      expect(failure.message, 'Message operation failed');
    });

    test('MessageSendFailure has correct properties', () {
      const failure = MessageSendFailure();

      expect(failure.message, 'Failed to send message. Please try again.');
      expect(failure.code, 'MESSAGE_SEND_FAILED');
    });

    test('MessageDeleteFailure has correct properties', () {
      const failure = MessageDeleteFailure();

      expect(failure.message, 'Failed to delete message. Please try again.');
      expect(failure.code, 'MESSAGE_DELETE_FAILED');
    });
  });

  group('AI/Translation Failures', () {
    test('AIServiceFailure with default message', () {
      const failure = AIServiceFailure();

      expect(
        failure.message,
        'AI service temporarily unavailable. Please try again.',
      );
    });

    test('TranslationFailure has correct properties', () {
      const failure = TranslationFailure();

      expect(
        failure.message,
        'Translation failed. The message will be shown in its original language.',
      );
      expect(failure.code, 'TRANSLATION_FAILED');
    });

    test('RateLimitExceededFailure without retry time', () {
      const failure = RateLimitExceededFailure();

      expect(
        failure.message,
        'Too many requests. Please try again in a few moments.',
      );
      expect(failure.code, 'RATE_LIMIT_EXCEEDED');
      expect(failure.retryAfter, isNull);
    });

    test('RateLimitExceededFailure with retry time', () {
      final retryTime = DateTime.now().add(const Duration(minutes: 5));
      final failure = RateLimitExceededFailure(retryAfter: retryTime);

      expect(failure.retryAfter, retryTime);
    });

    test('RateLimitExceededFailure equality', () {
      final time1 = DateTime(2025, 1, 1);
      final time2 = DateTime(2025, 1, 1);
      final time3 = DateTime(2025, 1, 2);

      final failure1 = RateLimitExceededFailure(retryAfter: time1);
      final failure2 = RateLimitExceededFailure(retryAfter: time2);
      final failure3 = RateLimitExceededFailure(retryAfter: time3);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });
  });

  group('Generic Failures', () {
    test('UnknownFailure with default message', () {
      const failure = UnknownFailure();

      expect(
        failure.message,
        'An unexpected error occurred. Please try again or contact support.',
      );
      expect(failure.code, 'UNKNOWN_ERROR');
    });

    test('UnknownFailure with custom message', () {
      const failure = UnknownFailure(message: 'Custom error');

      expect(failure.message, 'Custom error');
    });

    test('NotImplementedFailure has correct properties', () {
      const failure = NotImplementedFailure();

      expect(failure.message, 'This feature is coming soon!');
      expect(failure.code, 'NOT_IMPLEMENTED');
    });

    test('CancelledFailure has correct properties', () {
      const failure = CancelledFailure();

      expect(failure.message, 'Operation was cancelled.');
      expect(failure.code, 'CANCELLED');
    });
  });

  group('Failure Equality', () {
    test('failures with same properties are equal', () {
      const failure1 = NoInternetFailure();
      const failure2 = NoInternetFailure();

      expect(failure1, equals(failure2));
      expect(failure1.hashCode, equals(failure2.hashCode));
    });

    test('failures with different properties are not equal', () {
      const failure1 = ValidationFailure(message: 'Error 1');
      const failure2 = ValidationFailure(message: 'Error 2');

      expect(failure1, isNot(equals(failure2)));
    });

    test('different failure types are not equal', () {
      const failure1 = NoInternetFailure();
      const failure2 = NetworkTimeoutFailure();

      expect(failure1, isNot(equals(failure2)));
    });
  });
}
