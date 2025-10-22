import 'package:drift/drift.dart';

/// Messages table for storing chat messages
///
/// Stores all message data for offline-first architecture.
/// Includes support for translations, AI analysis, and sync status.
@DataClassName('MessageEntity')
class Messages extends Table {
  /// Unique message ID (matches Firestore document ID or temp ID)
  TextColumn get id => text()();

  /// Conversation ID this message belongs to
  TextColumn get conversationId => text()();

  /// Message text content
  TextColumn get messageText => text()();

  /// Sender user ID
  TextColumn get senderId => text()();

  /// Sender display name (cached for quick display)
  TextColumn get senderName => text()();

  /// Message timestamp
  DateTimeColumn get timestamp => dateTime()();

  /// Message type: 'text', 'image', 'file', etc.
  TextColumn get messageType => text().withDefault(const Constant('text'))();

  /// Message status: 'sending', 'sent', 'delivered', 'read', 'failed'
  TextColumn get status => text().withDefault(const Constant('sending'))();

  /// Detected language code
  TextColumn get detectedLanguage => text().nullable()();

  /// Translations as JSON object {lang: translation}
  TextColumn get translations => text().nullable()();

  /// Reply-to message ID
  TextColumn get replyTo => text().nullable()();

  /// Message metadata as JSON
  TextColumn get metadata => text().nullable()();

  /// AI analysis results as JSON
  TextColumn get aiAnalysis => text().nullable()();

  /// Embedding vector for RAG (stored as JSON array)
  TextColumn get embedding => text().nullable()();

  /// Sync status: 'pending', 'synced', 'failed'
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Retry count for failed sync attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Temporary ID for optimistic updates (null after sync)
  TextColumn get tempId => text().nullable()();

  /// Last sync attempt timestamp
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
