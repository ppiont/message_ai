/// Custom exceptions for the application
///
/// These exceptions are thrown by data sources (API, database, etc.)
/// and should be caught and converted to [Failure] objects by repositories.

/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({required this.message, this.code, this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ============================================================================
// Network Exceptions
// ============================================================================

/// Exception thrown when there's no internet connection
class NoInternetException extends AppException {
  const NoInternetException()
    : super(message: 'No internet connection available', code: 'NO_INTERNET');
}

/// Exception thrown when a network request times out
class NetworkTimeoutException extends AppException {
  const NetworkTimeoutException()
    : super(message: 'Network request timed out', code: 'NETWORK_TIMEOUT');
}

/// Exception thrown when the server returns an error
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
    super.originalError,
  });

  @override
  String toString() =>
      'ServerException: $message (status: $statusCode, code: $code)';
}

// ============================================================================
// Authentication Exceptions
// ============================================================================

/// Exception thrown when authentication fails
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Exception thrown when user is not authenticated
class UnauthenticatedException extends AppException {
  const UnauthenticatedException()
    : super(message: 'User is not authenticated', code: 'UNAUTHENTICATED');
}

/// Exception thrown when user doesn't have permission
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    String message = 'You do not have permission to perform this action',
  }) : super(message: message, code: 'UNAUTHORIZED');
}

/// Exception thrown when email is already in use
class EmailAlreadyInUseException extends AppException {
  const EmailAlreadyInUseException()
    : super(
        message: 'This email address is already in use',
        code: 'EMAIL_ALREADY_IN_USE',
      );
}

/// Exception thrown when credentials are invalid
class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException()
    : super(message: 'Invalid email or password', code: 'INVALID_CREDENTIALS');
}

/// Exception thrown when user account is disabled
class UserDisabledException extends AppException {
  const UserDisabledException()
    : super(message: 'This account has been disabled', code: 'USER_DISABLED');
}

// ============================================================================
// Database Exceptions
// ============================================================================

/// Exception thrown when a database operation fails
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Exception thrown when a record is not found
class RecordNotFoundException extends AppException {
  final String recordType;
  final String? recordId;

  const RecordNotFoundException({required this.recordType, this.recordId})
    : super(message: 'Record not found', code: 'RECORD_NOT_FOUND');

  @override
  String toString() {
    if (recordId != null) {
      return 'RecordNotFoundException: $recordType with id $recordId not found';
    }
    return 'RecordNotFoundException: $recordType not found';
  }
}

/// Exception thrown when a database constraint is violated
class ConstraintViolationException extends AppException {
  const ConstraintViolationException({
    required super.message,
    super.originalError,
  }) : super(code: 'CONSTRAINT_VIOLATION');
}

// ============================================================================
// Validation Exceptions
// ============================================================================

/// Exception thrown when input validation fails
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({required super.message, this.fieldErrors})
    : super(code: 'VALIDATION_ERROR');

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'ValidationException: $message\nField errors: $fieldErrors';
    }
    return 'ValidationException: $message';
  }
}

/// Exception thrown when input format is invalid
class InvalidFormatException extends AppException {
  final String fieldName;

  const InvalidFormatException({
    required this.fieldName,
    required super.message,
  }) : super(code: 'INVALID_FORMAT');

  @override
  String toString() => 'InvalidFormatException: $fieldName - $message';
}

// ============================================================================
// Storage Exceptions
// ============================================================================

/// Exception thrown when file upload fails
class FileUploadException extends AppException {
  const FileUploadException({required super.message, super.originalError})
    : super(code: 'FILE_UPLOAD_ERROR');
}

/// Exception thrown when file download fails
class FileDownloadException extends AppException {
  const FileDownloadException({required super.message, super.originalError})
    : super(code: 'FILE_DOWNLOAD_ERROR');
}

/// Exception thrown when storage quota is exceeded
class StorageQuotaExceededException extends AppException {
  const StorageQuotaExceededException()
    : super(message: 'Storage quota exceeded', code: 'STORAGE_QUOTA_EXCEEDED');
}

// ============================================================================
// Messaging Exceptions
// ============================================================================

/// Exception thrown when a message operation fails
class MessageException extends AppException {
  const MessageException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Exception thrown when message sending fails
class MessageSendFailedException extends AppException {
  const MessageSendFailedException({
    String message = 'Failed to send message',
    super.originalError,
  }) : super(message: message, code: 'MESSAGE_SEND_FAILED');
}

/// Exception thrown when message deletion fails
class MessageDeleteFailedException extends AppException {
  const MessageDeleteFailedException({
    String message = 'Failed to delete message',
    super.originalError,
  }) : super(message: message, code: 'MESSAGE_DELETE_FAILED');
}

// ============================================================================
// AI/Translation Exceptions
// ============================================================================

/// Exception thrown when AI/translation service fails
class AIServiceException extends AppException {
  const AIServiceException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Exception thrown when translation fails
class TranslationException extends AppException {
  const TranslationException({
    String message = 'Translation failed',
    super.originalError,
  }) : super(message: message, code: 'TRANSLATION_FAILED');
}

/// Exception thrown when AI rate limit is exceeded
class RateLimitExceededException extends AppException {
  final DateTime? retryAfter;

  const RateLimitExceededException({this.retryAfter})
    : super(message: 'Rate limit exceeded', code: 'RATE_LIMIT_EXCEEDED');

  @override
  String toString() {
    if (retryAfter != null) {
      return 'RateLimitExceededException: Rate limit exceeded. Try again after $retryAfter';
    }
    return 'RateLimitExceededException: Rate limit exceeded';
  }
}

// ============================================================================
// Generic Exceptions
// ============================================================================

/// Exception thrown for unknown/unexpected errors
class UnknownException extends AppException {
  const UnknownException({
    String message = 'An unexpected error occurred',
    super.originalError,
  }) : super(message: message, code: 'UNKNOWN_ERROR');
}

/// Exception thrown when a feature is not implemented
class NotImplementedException extends AppException {
  const NotImplementedException({
    String message = 'This feature is not yet implemented',
  }) : super(message: message, code: 'NOT_IMPLEMENTED');
}

/// Exception thrown when operation is cancelled
class CancelledException extends AppException {
  const CancelledException()
    : super(message: 'Operation was cancelled', code: 'CANCELLED');
}
