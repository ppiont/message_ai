import 'package:equatable/equatable.dart';

/// Base class for all failures
///
/// Failures represent errors in the domain/business logic layer.
/// They are returned by repositories and use cases instead of throwing exceptions.
/// This allows for functional error handling and better testability.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

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
  final int? statusCode;

  const ServerFailure({
    String message = 'Server error occurred. Please try again later.',
    super.code,
    this.statusCode,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, code, statusCode];
}

// ============================================================================
// Authentication Failures
// ============================================================================

/// Failure when authentication fails
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    String message = 'Authentication failed',
    super.code,
  }) : super(message: message);
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
    String message = 'You do not have permission to perform this action.',
  }) : super(message: message, code: 'UNAUTHORIZED');
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
    String message = 'Database error occurred',
    super.code,
  }) : super(message: message);
}

/// Failure when a record is not found
class RecordNotFoundFailure extends Failure {
  final String recordType;

  const RecordNotFoundFailure({required this.recordType, String? message})
    : super(
        message: message ?? 'The requested $recordType was not found.',
        code: 'RECORD_NOT_FOUND',
      );

  @override
  List<Object?> get props => [message, code, recordType];
}

/// Failure when a database constraint is violated
class ConstraintViolationFailure extends Failure {
  const ConstraintViolationFailure({
    String message = 'This operation violates a database constraint.',
  }) : super(message: message, code: 'CONSTRAINT_VIOLATION');
}

// ============================================================================
// Validation Failures
// ============================================================================

/// Failure when input validation fails
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    String message = 'Please correct the errors and try again.',
    this.fieldErrors,
  }) : super(message: message, code: 'VALIDATION_ERROR');

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
  final String fieldName;

  const InvalidFormatFailure({required this.fieldName, String? message})
    : super(
        message: message ?? 'Invalid format for $fieldName.',
        code: 'INVALID_FORMAT',
      );

  @override
  List<Object?> get props => [message, code, fieldName];
}

// ============================================================================
// Storage Failures
// ============================================================================

/// Failure when file upload fails
class FileUploadFailure extends Failure {
  const FileUploadFailure({
    String message = 'Failed to upload file. Please try again.',
  }) : super(message: message, code: 'FILE_UPLOAD_ERROR');
}

/// Failure when file download fails
class FileDownloadFailure extends Failure {
  const FileDownloadFailure({
    String message = 'Failed to download file. Please try again.',
  }) : super(message: message, code: 'FILE_DOWNLOAD_ERROR');
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
    String message = 'Message operation failed',
    super.code,
  }) : super(message: message);
}

/// Failure when message sending fails
class MessageSendFailure extends Failure {
  const MessageSendFailure({
    String message = 'Failed to send message. Please try again.',
  }) : super(message: message, code: 'MESSAGE_SEND_FAILED');
}

/// Failure when message deletion fails
class MessageDeleteFailure extends Failure {
  const MessageDeleteFailure({
    String message = 'Failed to delete message. Please try again.',
  }) : super(message: message, code: 'MESSAGE_DELETE_FAILED');
}

// ============================================================================
// AI/Translation Failures
// ============================================================================

/// Failure when AI/translation service fails
class AIServiceFailure extends Failure {
  const AIServiceFailure({
    String message = 'AI service temporarily unavailable. Please try again.',
    super.code,
  }) : super(message: message);
}

/// Failure when translation fails
class TranslationFailure extends Failure {
  const TranslationFailure({
    String message =
        'Translation failed. The message will be shown in its original language.',
  }) : super(message: message, code: 'TRANSLATION_FAILED');
}

/// Failure when rate limit is exceeded
class RateLimitExceededFailure extends Failure {
  final DateTime? retryAfter;

  const RateLimitExceededFailure({this.retryAfter})
    : super(
        message: 'Too many requests. Please try again in a few moments.',
        code: 'RATE_LIMIT_EXCEEDED',
      );

  @override
  List<Object?> get props => [message, code, retryAfter];
}

// ============================================================================
// Generic Failures
// ============================================================================

/// Failure for unknown/unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    String message =
        'An unexpected error occurred. Please try again or contact support.',
  }) : super(message: message, code: 'UNKNOWN_ERROR');
}

/// Failure when a feature is not implemented
class NotImplementedFailure extends Failure {
  const NotImplementedFailure({String message = 'This feature is coming soon!'})
    : super(message: message, code: 'NOT_IMPLEMENTED');
}

/// Failure when operation is cancelled
class CancelledFailure extends Failure {
  const CancelledFailure()
    : super(message: 'Operation was cancelled.', code: 'CANCELLED');
}
