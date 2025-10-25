import 'package:drift/drift.dart';

/// Message status table for per-user tracking of message delivery and read status
///
/// Replaces the inefficient deliveredToJson and readByJson map fields in Messages table.
/// Enables efficient queries like "unread count" and proper indexing for status lookups.
///
/// Each row represents the status of a message for a specific user.
/// For group chats, there will be multiple rows per message (one per participant).
@DataClassName('MessageStatusEntity')
class MessageStatus extends Table {
  /// Message ID (foreign key to Messages table)
  TextColumn get messageId => text()();

  /// User ID this status applies to
  TextColumn get userId => text()();

  /// Status: 'sent', 'delivered', 'read'
  ///
  /// - 'sent': Message sent by sender
  /// - 'delivered': Message received by this user's device
  /// - 'read': Message opened/viewed by this user
  TextColumn get status => text()();

  /// Timestamp when this status was set
  ///
  /// Nullable because 'sent' status may not have a timestamp
  /// (it's implicitly the message timestamp)
  DateTimeColumn get timestamp => dateTime().nullable()();

  /// Composite primary key: one status record per (message, user) pair
  @override
  Set<Column> get primaryKey => {messageId, userId};
}
