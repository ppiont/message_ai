import 'package:drift/drift.dart';

/// Cultural context analysis queue table
///
/// Stores pending cultural context analysis requests with retry logic.
/// This queue system ensures:
/// - Rate limiting (max 10 analyses per minute)
/// - Retry failed requests (max 3 attempts with exponential backoff)
/// - Persistence across app restarts
/// - Background processing
@DataClassName('CulturalContextQueueEntity')
class CulturalContextQueue extends Table {
  /// Unique queue entry ID
  TextColumn get id => text()();

  /// Message ID to analyze
  TextColumn get messageId => text()();

  /// Conversation ID for context
  TextColumn get conversationId => text()();

  /// Message text to analyze
  TextColumn get messageText => text()();

  /// Language code
  TextColumn get language => text()();

  /// Queue status: 'pending', 'processing', 'completed', 'failed'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Retry attempt count (0 = first attempt)
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Maximum retry attempts allowed
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();

  /// Timestamp when entry was added to queue
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp of last processing attempt
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Next retry time (for exponential backoff)
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  /// Error message if analysis failed
  TextColumn get errorMessage => text().nullable()();

  /// Priority (higher = processed first)
  IntColumn get priority => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
