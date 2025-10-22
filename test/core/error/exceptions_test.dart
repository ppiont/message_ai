import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';

void main() {
  group('Network Exceptions', () {
    test('NoInternetException has correct message and code', () {
      const exception = NoInternetException();

      expect(exception.message, 'No internet connection available');
      expect(exception.code, 'NO_INTERNET');
      expect(exception.originalError, isNull);
    });

    test('NetworkTimeoutException has correct message and code', () {
      const exception = NetworkTimeoutException();

      expect(exception.message, 'Network request timed out');
      expect(exception.code, 'NETWORK_TIMEOUT');
    });

    test('ServerException includes status code and original error', () {
      const originalError = 'Backend is down';
      const exception = ServerException(
        message: 'Internal server error',
        code: 'SERVER_ERROR',
        statusCode: 500,
        originalError: originalError,
      );

      expect(exception.message, 'Internal server error');
      expect(exception.code, 'SERVER_ERROR');
      expect(exception.statusCode, 500);
      expect(exception.originalError, originalError);
      expect(
        exception.toString(),
        'ServerException: Internal server error (status: 500, code: SERVER_ERROR)',
      );
    });
  });

  group('Authentication Exceptions', () {
    test('UnauthenticatedException has correct properties', () {
      const exception = UnauthenticatedException();

      expect(exception.message, 'User is not authenticated');
      expect(exception.code, 'UNAUTHENTICATED');
    });

    test('UnauthorizedException has default and custom message', () {
      const defaultException = UnauthorizedException();
      expect(
        defaultException.message,
        'You do not have permission to perform this action',
      );
      expect(defaultException.code, 'UNAUTHORIZED');

      const customException = UnauthorizedException(message: 'Custom message');
      expect(customException.message, 'Custom message');
    });

    test('EmailAlreadyInUseException has correct properties', () {
      const exception = EmailAlreadyInUseException();

      expect(exception.message, 'This email address is already in use');
      expect(exception.code, 'EMAIL_ALREADY_IN_USE');
    });

    test('InvalidCredentialsException has correct properties', () {
      const exception = InvalidCredentialsException();

      expect(exception.message, 'Invalid email or password');
      expect(exception.code, 'INVALID_CREDENTIALS');
    });

    test('UserDisabledException has correct properties', () {
      const exception = UserDisabledException();

      expect(exception.message, 'This account has been disabled');
      expect(exception.code, 'USER_DISABLED');
    });
  });

  group('Database Exceptions', () {
    test('DatabaseException with custom message', () {
      const exception = DatabaseException(
        message: 'Connection failed',
        code: 'DB_ERROR',
      );

      expect(exception.message, 'Connection failed');
      expect(exception.code, 'DB_ERROR');
    });

    test('RecordNotFoundException with type and ID', () {
      const exception = RecordNotFoundException(
        recordType: 'User',
        recordId: '123',
      );

      expect(exception.message, 'Record not found');
      expect(exception.code, 'RECORD_NOT_FOUND');
      expect(exception.recordType, 'User');
      expect(exception.recordId, '123');
      expect(
        exception.toString(),
        'RecordNotFoundException: User with id 123 not found',
      );
    });

    test('RecordNotFoundException without ID', () {
      const exception = RecordNotFoundException(recordType: 'Message');

      expect(exception.recordId, isNull);
      expect(
        exception.toString(),
        'RecordNotFoundException: Message not found',
      );
    });

    test('ConstraintViolationException has correct properties', () {
      const exception = ConstraintViolationException(
        message: 'Unique constraint violated',
      );

      expect(exception.message, 'Unique constraint violated');
      expect(exception.code, 'CONSTRAINT_VIOLATION');
    });
  });

  group('Validation Exceptions', () {
    test('ValidationException with field errors', () {
      final fieldErrors = {'email': 'Invalid format', 'password': 'Too short'};
      final exception = ValidationException(
        message: 'Validation failed',
        fieldErrors: fieldErrors,
      );

      expect(exception.message, 'Validation failed');
      expect(exception.code, 'VALIDATION_ERROR');
      expect(exception.fieldErrors, fieldErrors);
      expect(exception.toString(), contains('Field errors:'));
    });

    test('ValidationException without field errors', () {
      const exception = ValidationException(
        message: 'Generic validation error',
      );

      expect(exception.fieldErrors, isNull);
      expect(
        exception.toString(),
        'ValidationException: Generic validation error',
      );
    });

    test('InvalidFormatException has correct properties', () {
      const exception = InvalidFormatException(
        fieldName: 'phoneNumber',
        message: 'Must be 10 digits',
      );

      expect(exception.fieldName, 'phoneNumber');
      expect(exception.message, 'Must be 10 digits');
      expect(exception.code, 'INVALID_FORMAT');
      expect(
        exception.toString(),
        'InvalidFormatException: phoneNumber - Must be 10 digits',
      );
    });
  });

  group('Storage Exceptions', () {
    test('FileUploadException has correct properties', () {
      const exception = FileUploadException(message: 'File too large');

      expect(exception.message, 'File too large');
      expect(exception.code, 'FILE_UPLOAD_ERROR');
    });

    test('FileDownloadException has correct properties', () {
      const exception = FileDownloadException(message: 'Network error');

      expect(exception.message, 'Network error');
      expect(exception.code, 'FILE_DOWNLOAD_ERROR');
    });

    test('StorageQuotaExceededException has correct properties', () {
      const exception = StorageQuotaExceededException();

      expect(exception.message, 'Storage quota exceeded');
      expect(exception.code, 'STORAGE_QUOTA_EXCEEDED');
    });
  });

  group('Messaging Exceptions', () {
    test('MessageSendFailedException with default message', () {
      const exception = MessageSendFailedException();

      expect(exception.message, 'Failed to send message');
      expect(exception.code, 'MESSAGE_SEND_FAILED');
    });

    test('MessageSendFailedException with custom message', () {
      const exception = MessageSendFailedException(message: 'User offline');

      expect(exception.message, 'User offline');
    });

    test('MessageDeleteFailedException has correct properties', () {
      const exception = MessageDeleteFailedException();

      expect(exception.message, 'Failed to delete message');
      expect(exception.code, 'MESSAGE_DELETE_FAILED');
    });
  });

  group('AI/Translation Exceptions', () {
    test('TranslationException has correct properties', () {
      const exception = TranslationException();

      expect(exception.message, 'Translation failed');
      expect(exception.code, 'TRANSLATION_FAILED');
    });

    test('RateLimitExceededException without retry time', () {
      const exception = RateLimitExceededException();

      expect(exception.message, 'Rate limit exceeded');
      expect(exception.code, 'RATE_LIMIT_EXCEEDED');
      expect(exception.retryAfter, isNull);
      expect(
        exception.toString(),
        'RateLimitExceededException: Rate limit exceeded',
      );
    });

    test('RateLimitExceededException with retry time', () {
      final retryTime = DateTime.now().add(const Duration(minutes: 5));
      final exception = RateLimitExceededException(retryAfter: retryTime);

      expect(exception.retryAfter, retryTime);
      expect(exception.toString(), contains('Try again after'));
    });
  });

  group('Generic Exceptions', () {
    test('UnknownException with default message', () {
      const exception = UnknownException();

      expect(exception.message, 'An unexpected error occurred');
      expect(exception.code, 'UNKNOWN_ERROR');
    });

    test('UnknownException with custom message and original error', () {
      final originalError = Exception('Original error');
      final exception = UnknownException(
        message: 'Something went wrong',
        originalError: originalError,
      );

      expect(exception.message, 'Something went wrong');
      expect(exception.originalError, originalError);
    });

    test('NotImplementedException has correct properties', () {
      const exception = NotImplementedException();

      expect(exception.message, 'This feature is not yet implemented');
      expect(exception.code, 'NOT_IMPLEMENTED');
    });

    test('CancelledException has correct properties', () {
      const exception = CancelledException();

      expect(exception.message, 'Operation was cancelled');
      expect(exception.code, 'CANCELLED');
    });
  });
}
