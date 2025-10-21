import 'package:drift/drift.dart';

/// Conversations table for storing chat metadata
///
/// Handles both 1-to-1 direct messages and group conversations.
/// Stores conversation metadata and last message info for quick list rendering.
@DataClassName('ConversationEntity')
class Conversations extends Table {
  /// Unique conversation ID (matches Firestore document ID)
  TextColumn get documentId => text()();

  /// Conversation type: 'direct' or 'group'
  TextColumn get conversationType => text()();

  /// Group name (null for direct conversations)
  TextColumn get groupName => text().nullable()();

  /// Group image URL (null for direct conversations)
  TextColumn get groupImage => text().nullable()();

  /// Participant user IDs as JSON array
  TextColumn get participantIds => text()();

  /// Participant details as JSON (for quick display)
  TextColumn get participants => text()();

  /// Admin user IDs as JSON array (for group chats)
  TextColumn get adminIds => text().nullable()();

  /// Last message text preview
  TextColumn get lastMessageText => text().nullable()();

  /// Last message sender ID
  TextColumn get lastMessageSenderId => text().nullable()();

  /// Last message sender name
  TextColumn get lastMessageSenderName => text().nullable()();

  /// Last message timestamp
  DateTimeColumn get lastMessageTimestamp => dateTime().nullable()();

  /// Last message type (text, image, etc.)
  TextColumn get lastMessageType => text().nullable()();

  /// Last message translations as JSON
  TextColumn get lastMessageTranslations => text().nullable()();

  /// Last update timestamp
  DateTimeColumn get lastUpdatedAt => dateTime()();

  /// Conversation initiated timestamp
  DateTimeColumn get initiatedAt => dateTime()();

  /// Unread count per user as JSON object
  TextColumn get unreadCount => text()();

  /// Translation enabled flag
  BoolColumn get translationEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Auto-detect language flag
  BoolColumn get autoDetectLanguage =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {documentId};
}
