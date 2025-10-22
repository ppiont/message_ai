import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';

void main() {
  group('ErrorMapper - AppExceptions', () {
    test('maps NoInternetException to NoInternetFailure', () {
      const exception = NoInternetException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<NoInternetFailure>());
      expect(failure.code, 'NO_INTERNET');
    });

    test('maps NetworkTimeoutException to NetworkTimeoutFailure', () {
      const exception = NetworkTimeoutException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<NetworkTimeoutFailure>());
      expect(failure.code, 'NETWORK_TIMEOUT');
    });

    test('maps ServerException to ServerFailure', () {
      const exception = ServerException(
        message: 'Internal error',
        code: 'SERVER_ERROR',
        statusCode: 500,
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Internal error');
      expect(failure.code, 'SERVER_ERROR');
      expect((failure as ServerFailure).statusCode, 500);
    });

    test('maps UnauthenticatedException to UnauthenticatedFailure', () {
      const exception = UnauthenticatedException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<UnauthenticatedFailure>());
    });

    test('maps UnauthorizedException to UnauthorizedFailure', () {
      const exception = UnauthorizedException(message: 'Admin only');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'Admin only');
    });

    test('maps EmailAlreadyInUseException to EmailAlreadyInUseFailure', () {
      const exception = EmailAlreadyInUseException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<EmailAlreadyInUseFailure>());
    });

    test('maps InvalidCredentialsException to InvalidCredentialsFailure', () {
      const exception = InvalidCredentialsException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<InvalidCredentialsFailure>());
    });

    test('maps UserDisabledException to UserDisabledFailure', () {
      const exception = UserDisabledException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<UserDisabledFailure>());
    });

    test('maps RecordNotFoundException to RecordNotFoundFailure', () {
      const exception = RecordNotFoundException(
        recordType: 'User',
        recordId: '123',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<RecordNotFoundFailure>());
      expect((failure as RecordNotFoundFailure).recordType, 'User');
    });

    test('maps ConstraintViolationException to ConstraintViolationFailure', () {
      const exception = ConstraintViolationException(
        message: 'Unique constraint violated',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ConstraintViolationFailure>());
      expect(failure.message, 'Unique constraint violated');
    });

    test('maps ValidationException to ValidationFailure', () {
      const exception = ValidationException(
        message: 'Validation failed',
        fieldErrors: {'email': 'Invalid'},
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, {'email': 'Invalid'});
    });

    test('maps InvalidFormatException to InvalidFormatFailure', () {
      const exception = InvalidFormatException(
        fieldName: 'phoneNumber',
        message: 'Invalid format',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<InvalidFormatFailure>());
      expect((failure as InvalidFormatFailure).fieldName, 'phoneNumber');
    });

    test('maps FileUploadException to FileUploadFailure', () {
      const exception = FileUploadException(message: 'Upload failed');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<FileUploadFailure>());
      expect(failure.message, 'Upload failed');
    });

    test('maps FileDownloadException to FileDownloadFailure', () {
      const exception = FileDownloadException(message: 'Download failed');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<FileDownloadFailure>());
      expect(failure.message, 'Download failed');
    });

    test(
      'maps StorageQuotaExceededException to StorageQuotaExceededFailure',
      () {
        const exception = StorageQuotaExceededException();

        final failure = ErrorMapper.mapExceptionToFailure(exception);

        expect(failure, isA<StorageQuotaExceededFailure>());
      },
    );

    test('maps MessageSendFailedException to MessageSendFailure', () {
      const exception = MessageSendFailedException(message: 'Send failed');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<MessageSendFailure>());
      expect(failure.message, 'Send failed');
    });

    test('maps MessageDeleteFailedException to MessageDeleteFailure', () {
      const exception = MessageDeleteFailedException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<MessageDeleteFailure>());
    });

    test('maps TranslationException to TranslationFailure', () {
      const exception = TranslationException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<TranslationFailure>());
    });

    test('maps RateLimitExceededException to RateLimitExceededFailure', () {
      final retryTime = DateTime.now();
      final exception = RateLimitExceededException(retryAfter: retryTime);

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<RateLimitExceededFailure>());
      expect((failure as RateLimitExceededFailure).retryAfter, retryTime);
    });

    test('maps NotImplementedException to NotImplementedFailure', () {
      const exception = NotImplementedException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<NotImplementedFailure>());
    });

    test('maps CancelledException to CancelledFailure', () {
      const exception = CancelledException();

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<CancelledFailure>());
    });
  });

  group('ErrorMapper - Firebase Auth Exceptions', () {
    test('maps email-already-in-use to EmailAlreadyInUseFailure', () {
      final exception = firebase_auth.FirebaseAuthException(
        code: 'email-already-in-use',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<EmailAlreadyInUseFailure>());
    });

    test('maps wrong-password to InvalidCredentialsFailure', () {
      final exception = firebase_auth.FirebaseAuthException(
        code: 'wrong-password',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<InvalidCredentialsFailure>());
    });

    test('maps user-disabled to UserDisabledFailure', () {
      final exception = firebase_auth.FirebaseAuthException(
        code: 'user-disabled',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<UserDisabledFailure>());
    });

    test('maps weak-password to ValidationFailure', () {
      final exception = firebase_auth.FirebaseAuthException(
        code: 'weak-password',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors?['password'],
        isNotNull,
      );
    });

    test('maps network-request-failed to NoInternetFailure', () {
      final exception = firebase_auth.FirebaseAuthException(
        code: 'network-request-failed',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<NoInternetFailure>());
    });

    test('maps too-many-requests to RateLimitExceededFailure', () {
      final exception = firebase_auth.FirebaseAuthException(
        code: 'too-many-requests',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<RateLimitExceededFailure>());
    });

    test('maps unknown auth code to AuthenticationFailure', () {
      final exception = firebase_auth.FirebaseAuthException(
        code: 'unknown-code',
        message: 'Unknown error',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<AuthenticationFailure>());
      expect(failure.message, 'Unknown error');
      expect(failure.code, 'unknown-code');
    });
  });

  group('ErrorMapper - Firebase Exceptions', () {
    test('maps permission-denied to UnauthorizedFailure', () {
      final exception = FirebaseException(
        plugin: 'firestore',
        code: 'permission-denied',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<UnauthorizedFailure>());
    });

    test('maps not-found to RecordNotFoundFailure', () {
      final exception = FirebaseException(
        plugin: 'firestore',
        code: 'not-found',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<RecordNotFoundFailure>());
    });

    test('maps quota-exceeded to StorageQuotaExceededFailure', () {
      final exception = FirebaseException(
        plugin: 'storage',
        code: 'quota-exceeded',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<StorageQuotaExceededFailure>());
    });

    test('maps cancelled to CancelledFailure', () {
      final exception = FirebaseException(
        plugin: 'firestore',
        code: 'cancelled',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<CancelledFailure>());
    });

    test('maps deadline-exceeded to NetworkTimeoutFailure', () {
      final exception = FirebaseException(
        plugin: 'firestore',
        code: 'deadline-exceeded',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<NetworkTimeoutFailure>());
    });

    test('maps invalid-argument to ValidationFailure', () {
      final exception = FirebaseException(
        plugin: 'firestore',
        code: 'invalid-argument',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ValidationFailure>());
    });

    test('maps unknown Firebase code to ServerFailure', () {
      final exception = FirebaseException(
        plugin: 'firestore',
        code: 'unknown-code',
        message: 'Unknown error',
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Unknown error');
      expect(failure.code, 'unknown-code');
    });
  });

  group('ErrorMapper - Network Exceptions', () {
    test('maps SocketException to NoInternetFailure', () {
      const exception = SocketException('No network');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<NoInternetFailure>());
    });

    test('maps TimeoutException to NetworkTimeoutFailure', () {
      final exception = TimeoutException('Timeout');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<NetworkTimeoutFailure>());
    });

    test('maps HttpException to ServerFailure', () {
      const exception = HttpException('Bad request');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Bad request');
    });
  });

  group('ErrorMapper - Format Exceptions', () {
    test('maps FormatException to InvalidFormatFailure', () {
      const exception = FormatException('Invalid JSON');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<InvalidFormatFailure>());
      expect((failure as InvalidFormatFailure).fieldName, 'input');
      expect(failure.message, 'Invalid JSON');
    });
  });

  group('ErrorMapper - Unknown Exceptions', () {
    test('maps unknown exception to UnknownFailure', () {
      final exception = Exception('Random error');

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<UnknownFailure>());
      expect(failure.message, contains('Random error'));
    });

    test('maps string error to UnknownFailure', () {
      const error = 'String error';

      final failure = ErrorMapper.mapExceptionToFailure(error);

      expect(failure, isA<UnknownFailure>());
      expect(failure.message, contains('String error'));
    });
  });

  group('ErrorMapper - mapWithContext', () {
    test('adds context to unknown failures', () {
      final exception = Exception('Something broke');

      final failure = ErrorMapper.mapWithContext(exception, 'file upload');

      expect(failure, isA<UnknownFailure>());
      expect(failure.message, contains('file upload'));
      expect(failure.message, contains('Something broke'));
    });

    test('does not modify non-unknown failures', () {
      const exception = NoInternetException();

      final failure = ErrorMapper.mapWithContext(exception, 'API call');

      expect(failure, isA<NoInternetFailure>());
      expect(failure.message, isNot(contains('API call')));
    });
  });

  group('ErrorMapper - Helper Methods', () {
    test('isRetryable returns true for retryable failures', () {
      expect(ErrorMapper.isRetryable(const NoInternetFailure()), isTrue);
      expect(ErrorMapper.isRetryable(const NetworkTimeoutFailure()), isTrue);
      expect(ErrorMapper.isRetryable(const ServerFailure()), isTrue);
      expect(ErrorMapper.isRetryable(const RateLimitExceededFailure()), isTrue);
    });

    test('isRetryable returns false for non-retryable failures', () {
      expect(ErrorMapper.isRetryable(const ValidationFailure()), isFalse);
      expect(ErrorMapper.isRetryable(const UnauthenticatedFailure()), isFalse);
      expect(ErrorMapper.isRetryable(const CancelledFailure()), isFalse);
    });

    test('requiresAuthentication returns true for auth-related failures', () {
      expect(
        ErrorMapper.requiresAuthentication(const UnauthenticatedFailure()),
        isTrue,
      );
      expect(
        ErrorMapper.requiresAuthentication(
          const UnauthorizedFailure(message: 'requires-recent-login'),
        ),
        isFalse, // Only true if code is 'requires-recent-login', not message
      );
    });

    test('requiresAuthentication returns false for other failures', () {
      expect(
        ErrorMapper.requiresAuthentication(const NoInternetFailure()),
        isFalse,
      );
      expect(
        ErrorMapper.requiresAuthentication(const ValidationFailure()),
        isFalse,
      );
    });
  });
}
