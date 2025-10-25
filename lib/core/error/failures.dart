import 'package:equatable/equatable.dart';

/// Base class for all failures
///
/// Failures represent errors in the domain/business logic layer.
/// They are returned by repositories and use cases instead of throwing exceptions.
/// This allows for functional error handling and better testability.
abstract class Failure extends Equatable {
  const Failure({required this.message, this.code});
  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure: $message (code: $code)';
}

// ============================================================================
// Network Failures
// ============================================================================

/// Failure when there's no internet connection
class NoInternetFailure extends Failure {
  const NoInternetFailure()
    : super(
        message: 'No internet connection. Please check your network settings.',
        code: 'NO_INTERNET',
      );
}

/// Failure when network request times out
class NetworkTimeoutFailure extends Failure {
  const NetworkTimeoutFailure()
    : super(
        message:
            'Request timed out. Please check your connection and try again.',
        code: 'NETWORK_TIMEOUT',
      );
}

/// Failure when server returns an error
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error occurred. Please try again later.',
    super.code,
    this.statusCode,
  });
  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}

// ============================================================================
// Authentication Failures
// ============================================================================

/// Failure when authentication fails
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Authentication failed',
    super.code,
  });
}

/// Failure when user is not authenticated
class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure()
    : super(
        message: 'You must be signed in to perform this action.',
        code: 'UNAUTHENTICATED',
      );
}

/// Failure when user lacks permission
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'You do not have permission to perform this action.',
  }) : super(code: 'UNAUTHORIZED');
}

/// Failure when email is already in use
class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure()
    : super(
        message: 'This email address is already in use. Please try another.',
        code: 'EMAIL_ALREADY_IN_USE',
      );
}

/// Failure when credentials are invalid
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure()
    : super(
        message: 'Invalid email or password. Please try again.',
        code: 'INVALID_CREDENTIALS',
      );
}

/// Failure when user account is disabled
class UserDisabledFailure extends Failure {
  const UserDisabledFailure()
    : super(
        message:
            'This account has been disabled. Please contact support for assistance.',
        code: 'USER_DISABLED',
      );
}

// ============================================================================
// Database Failures
// ============================================================================

/// Failure when a database operation fails
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database error occurred',
    super.code,
  });
}

/// Failure when a record is not found
class RecordNotFoundFailure extends Failure {
  const RecordNotFoundFailure({required this.recordType, String? message})
    : super(
        message: message ?? 'The requested $recordType was not found.',
        code: 'RECORD_NOT_FOUND',
      );
  final String recordType;

  @override
  List<Object?> get props => [message, code, recordType];
}

/// Failure when a database constraint is violated
class ConstraintViolationFailure extends Failure {
  const ConstraintViolationFailure({
    super.message = 'This operation violates a database constraint.',
  }) : super(code: 'CONSTRAINT_VIOLATION');
}

// ============================================================================
// Validation Failures
// ============================================================================

/// Failure when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Please correct the errors and try again.',
    this.fieldErrors,
  }) : super(code: 'VALIDATION_ERROR');
  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => [message, code, fieldErrors];

  /// Get error for a specific field
  String? getFieldError(String fieldName) => fieldErrors?[fieldName];

  /// Check if a specific field has an error
  bool hasFieldError(String fieldName) =>
      fieldErrors?.containsKey(fieldName) ?? false;
}

/// Failure when input format is invalid
class InvalidFormatFailure extends Failure {
  const InvalidFormatFailure({required this.fieldName, String? message})
    : super(
        message: message ?? 'Invalid format for $fieldName.',
        code: 'INVALID_FORMAT',
      );
  final String fieldName;

  @override
  List<Object?> get props => [message, code, fieldName];
}

// ============================================================================
// Storage Failures
// ============================================================================

/// Failure when file upload fails
class FileUploadFailure extends Failure {
  const FileUploadFailure({
    super.message = 'Failed to upload file. Please try again.',
  }) : super(code: 'FILE_UPLOAD_ERROR');
}

/// Failure when file download fails
class FileDownloadFailure extends Failure {
  const FileDownloadFailure({
    super.message = 'Failed to download file. Please try again.',
  }) : super(code: 'FILE_DOWNLOAD_ERROR');
}

/// Failure when storage quota is exceeded
class StorageQuotaExceededFailure extends Failure {
  const StorageQuotaExceededFailure()
    : super(
        message: 'Storage quota exceeded. Please free up some space.',
        code: 'STORAGE_QUOTA_EXCEEDED',
      );
}

// ============================================================================
// Messaging Failures
// ============================================================================

/// Failure when a message operation fails
class MessageFailure extends Failure {
  const MessageFailure({
    super.message = 'Message operation failed',
    super.code,
  });
}

/// Failure when message sending fails
class MessageSendFailure extends Failure {
  const MessageSendFailure({
    super.message = 'Failed to send message. Please try again.',
  }) : super(code: 'MESSAGE_SEND_FAILED');
}

/// Failure when message deletion fails
class MessageDeleteFailure extends Failure {
  const MessageDeleteFailure({
    super.message = 'Failed to delete message. Please try again.',
  }) : super(code: 'MESSAGE_DELETE_FAILED');
}

// ============================================================================
// AI/Translation Failures
// ============================================================================

/// Failure when AI/translation service fails
class AIServiceFailure extends Failure {
  const AIServiceFailure({
    super.message = 'AI service temporarily unavailable. Please try again.',
    super.code,
  });
}

/// Failure when translation fails
class TranslationFailure extends Failure {
  const TranslationFailure({
    super.message =
        'Translation failed. The message will be shown in its original language.',
  }) : super(code: 'TRANSLATION_FAILED');
}

/// Failure when rate limit is exceeded
class RateLimitExceededFailure extends Failure {
  const RateLimitExceededFailure({this.retryAfter})
    : super(
        message: 'Too many requests. Please try again in a few moments.',
        code: 'RATE_LIMIT_EXCEEDED',
      );
  final DateTime? retryAfter;

  @override
  List<Object?> get props => [message, code, retryAfter];
}

// ============================================================================
// Generic Failures
// ============================================================================

/// Failure for unknown/unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message =
        'An unexpected error occurred. Please try again or contact support.',
  }) : super(code: 'UNKNOWN_ERROR');
}

/// Failure when a feature is not implemented
class NotImplementedFailure extends Failure {
  const NotImplementedFailure({super.message = 'This feature is coming soon!'})
    : super(code: 'NOT_IMPLEMENTED');
}

/// Failure when operation is cancelled
class CancelledFailure extends Failure {
  const CancelledFailure()
    : super(message: 'Operation was cancelled.', code: 'CANCELLED');
}
