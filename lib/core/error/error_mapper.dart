import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';

/// Maps exceptions to failures
///
/// This utility class converts low-level exceptions (from data sources)
/// into high-level failures (for the domain layer).
///
/// Usage in repositories:
/// ```dart
/// try {
///   final result = await dataSource.getSomething();
///   return Right(result);
/// } catch (e) {
///   return Left(ErrorMapper.mapExceptionToFailure(e));
/// }
/// ```
class ErrorMapper {
  /// Maps any exception to a [Failure]
  static Failure mapExceptionToFailure(dynamic exception) {
    // Handle our custom exceptions first
    if (exception is AppException) {
      return _mapAppException(exception);
    }

    // Handle Firebase Auth exceptions
    if (exception is firebase_auth.FirebaseAuthException) {
      return _mapFirebaseAuthException(exception);
    }

    // Handle Firestore exceptions
    if (exception is FirebaseException) {
      return _mapFirebaseException(exception);
    }

    // Handle Drift exceptions
    if (exception is DriftWrappedException) {
      return _mapDriftException(exception);
    }

    // Handle network exceptions
    if (exception is SocketException) {
      return const NoInternetFailure();
    }

    if (exception is TimeoutException) {
      return const NetworkTimeoutFailure();
    }

    if (exception is HttpException) {
      return ServerFailure(
        message: exception.message,
        statusCode: exception.uri != null ? null : 500,
      );
    }

    // Handle format exceptions
    if (exception is FormatException) {
      return InvalidFormatFailure(
        fieldName: 'input',
        message: exception.message,
      );
    }

    // Default to unknown failure
    return UnknownFailure(message: exception.toString());
  }

  /// Maps our custom [AppException] to [Failure]
  static Failure _mapAppException(AppException exception) {
    if (exception is NoInternetException) {
      return const NoInternetFailure();
    }

    if (exception is NetworkTimeoutException) {
      return const NetworkTimeoutFailure();
    }

    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        code: exception.code,
      );
    }

    if (exception is UnauthenticatedException) {
      return const UnauthenticatedFailure();
    }

    if (exception is UnauthorizedException) {
      return UnauthorizedFailure(message: exception.message);
    }

    if (exception is EmailAlreadyInUseException) {
      return const EmailAlreadyInUseFailure();
    }

    if (exception is InvalidCredentialsException) {
      return const InvalidCredentialsFailure();
    }

    if (exception is UserDisabledException) {
      return const UserDisabledFailure();
    }

    if (exception is RecordNotFoundException) {
      return RecordNotFoundFailure(recordType: exception.recordType);
    }

    if (exception is RecordAlreadyExistsException) {
      return DatabaseFailure(message: exception.message);
    }

    if (exception is ConstraintViolationException) {
      return ConstraintViolationFailure(message: exception.message);
    }

    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        fieldErrors: exception.fieldErrors,
      );
    }

    if (exception is InvalidFormatException) {
      return InvalidFormatFailure(
        fieldName: exception.fieldName,
        message: exception.message,
      );
    }

    if (exception is FileUploadException) {
      return FileUploadFailure(message: exception.message);
    }

    if (exception is FileDownloadException) {
      return FileDownloadFailure(message: exception.message);
    }

    if (exception is StorageQuotaExceededException) {
      return const StorageQuotaExceededFailure();
    }

    if (exception is MessageSendFailedException) {
      return MessageSendFailure(message: exception.message);
    }

    if (exception is MessageDeleteFailedException) {
      return MessageDeleteFailure(message: exception.message);
    }

    if (exception is TranslationException) {
      return TranslationFailure(message: exception.message);
    }

    if (exception is RateLimitExceededException) {
      return RateLimitExceededFailure(retryAfter: exception.retryAfter);
    }

    if (exception is NotImplementedException) {
      return NotImplementedFailure(message: exception.message);
    }

    if (exception is CancelledException) {
      return const CancelledFailure();
    }

    // Generic AppException
    return UnknownFailure(message: exception.message);
  }

  /// Maps Firebase Auth exceptions to [Failure]
  static Failure _mapFirebaseAuthException(
    firebase_auth.FirebaseAuthException exception,
  ) {
    switch (exception.code) {
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();

      case 'wrong-password':
      case 'invalid-email':
      case 'user-not-found':
      case 'invalid-credential':
        return const InvalidCredentialsFailure();

      case 'user-disabled':
        return const UserDisabledFailure();

      case 'weak-password':
        return const ValidationFailure(
          message: 'Password is too weak. Please use a stronger password.',
          fieldErrors: {'password': 'Password is too weak'},
        );

      case 'network-request-failed':
        return const NoInternetFailure();

      case 'too-many-requests':
        return const RateLimitExceededFailure();

      case 'operation-not-allowed':
        return UnauthorizedFailure(
          message: exception.message ?? 'This operation is not allowed.',
        );

      case 'requires-recent-login':
        return const UnauthenticatedFailure();

      default:
        return AuthenticationFailure(
          message: exception.message ?? 'Authentication failed',
          code: exception.code,
        );
    }
  }

  /// Maps Firebase exceptions (Firestore, Storage, etc.) to [Failure]
  static Failure _mapFirebaseException(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return UnauthorizedFailure(
          message:
              exception.message ??
              'You do not have permission to perform this action.',
        );

      case 'not-found':
        return const RecordNotFoundFailure(recordType: 'resource');

      case 'already-exists':
        return ConstraintViolationFailure(
          message: exception.message ?? 'This resource already exists.',
        );

      case 'resource-exhausted':
      case 'quota-exceeded':
        return const StorageQuotaExceededFailure();

      case 'cancelled':
        return const CancelledFailure();

      case 'data-loss':
      case 'internal':
        return ServerFailure(
          message: 'An internal error occurred. Please try again later.',
          code: exception.code,
        );

      case 'unavailable':
        return const ServerFailure(
          message: 'Service temporarily unavailable. Please try again.',
        );

      case 'deadline-exceeded':
        return const NetworkTimeoutFailure();

      case 'invalid-argument':
      case 'failed-precondition':
        return ValidationFailure(
          message: exception.message ?? 'Invalid input. Please try again.',
        );

      case 'out-of-range':
        return const ValidationFailure(message: 'Value is out of range.');

      case 'unimplemented':
        return const NotImplementedFailure();

      default:
        return ServerFailure(
          message: exception.message ?? 'Server error occurred',
          code: exception.code,
        );
    }
  }

  /// Maps Drift (SQLite) exceptions to [Failure]
  static Failure _mapDriftException(DriftWrappedException exception) {
    final message = exception.message.toLowerCase();

    // Check for constraint violations
    if (message.contains('unique') ||
        message.contains('constraint') ||
        message.contains('foreign key')) {
      return const ConstraintViolationFailure(

      );
    }

    // Check for not found errors
    if (message.contains('not found') || message.contains('no such')) {
      return const RecordNotFoundFailure(recordType: 'record');
    }

    // Generic database error
    return DatabaseFailure(
      message: 'Database operation failed: ${exception.message}',
    );
  }

  /// Maps exceptions from a specific source with context
  ///
  /// Useful when you want to provide more context about where the error occurred.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await uploadFile();
  /// } catch (e) {
  ///   return Left(ErrorMapper.mapWithContext(e, 'file upload'));
  /// }
  /// ```
  static Failure mapWithContext(dynamic exception, String context) {
    final failure = mapExceptionToFailure(exception);

    // For unknown failures, add context to the message
    if (failure is UnknownFailure) {
      return UnknownFailure(
        message: 'Error during $context: ${failure.message}',
      );
    }

    return failure;
  }

  /// Helper method to check if an error is retryable
  static bool isRetryable(Failure failure) => failure is NoInternetFailure ||
        failure is NetworkTimeoutFailure ||
        failure is ServerFailure ||
        failure is RateLimitExceededFailure;

  /// Helper method to check if an error requires authentication
  static bool requiresAuthentication(Failure failure) => failure is UnauthenticatedFailure ||
        (failure is UnauthorizedFailure &&
            failure.code == 'requires-recent-login');
}
