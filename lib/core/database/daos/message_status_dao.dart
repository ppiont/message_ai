import 'package:drift/drift.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/tables/message_status_table.dart';
import 'package:message_ai/core/database/tables/messages_table.dart';

part 'message_status_dao.g.dart';

/// Data Access Object for MessageStatus table
///
/// Handles all local database operations for per-user message status tracking including:
/// - Marking messages as delivered
/// - Marking messages as read
/// - Querying unread counts
/// - Watching status updates for real-time UI
///
/// This replaces the inefficient deliveredToJson and readByJson map-based approach.
@DriftAccessor(tables: [MessageStatus, Messages])
class MessageStatusDao extends DatabaseAccessor<AppDatabase>
    with _$MessageStatusDaoMixin {
  MessageStatusDao(super.db);

  // ============================================================================
  // Write Methods
  // ============================================================================

  /// Mark all undelivered messages in a conversation as delivered for a user
  ///
  /// This is called when a user opens a conversation.
  /// It finds all messages in the conversation that haven't been marked as
  /// delivered yet and creates/updates status records.
  ///
  /// Uses batch operations for efficiency.
  Future<void> markAllAsDelivered({
    required String conversationId,
    required String userId,
    required DateTime timestamp,
  }) async {
    // Get all messages in conversation
    final messagesInConversation = await (select(
      messages,
    )..where((m) => m.conversationId.equals(conversationId))).get();

    // Prepare batch insert/update
    await batch((batch) {
      for (final message in messagesInConversation) {
        // Skip messages sent by the user themselves
        if (message.senderId == userId) {
          continue;
        }

        // Insert or replace status record
        batch.insert(
          messageStatus,
          MessageStatusCompanion.insert(
            messageId: message.id,
            userId: userId,
            status: 'delivered',
            timestamp: Value(timestamp),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Mark a specific message as read for a user
  ///
  /// This is called when a message becomes visible in the viewport
  /// or when the user explicitly reads it.
  Future<void> markAsRead({
    required String messageId,
    required String userId,
    required DateTime timestamp,
  }) async {
    await into(messageStatus).insert(
      MessageStatusCompanion.insert(
        messageId: messageId,
        userId: userId,
        status: 'read',
        timestamp: Value(timestamp),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Mark a message as sent (initial status)
  ///
  /// This is called when a message is first created by the sender.
  Future<void> markAsSent({
    required String messageId,
    required String userId,
    DateTime? timestamp,
  }) async {
    await into(messageStatus).insert(
      MessageStatusCompanion.insert(
        messageId: messageId,
        userId: userId,
        status: 'sent',
        timestamp: Value(timestamp),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Generic upsert for any status
  ///
  /// Used by real-time Firestore listeners to update local status
  Future<void> upsertStatus({
    required String messageId,
    required String userId,
    required String status,
    required DateTime timestamp,
  }) async {
    await into(messageStatus).insert(
      MessageStatusCompanion.insert(
        messageId: messageId,
        userId: userId,
        status: status,
        timestamp: Value(timestamp),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Bulk insert status records
  ///
  /// Useful for initial sync or migration
  Future<void> insertStatusRecords(List<MessageStatusCompanion> records) async {
    await batch((batch) {
      for (final record in records) {
        batch.insert(messageStatus, record, mode: InsertMode.insertOrReplace);
      }
    });
  }

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get unread message count for a conversation and user
  ///
  /// Returns the number of messages that are either:
  /// - Not delivered to the user yet (no status record)
  /// - Delivered but not read (status = 'delivered')
  ///
  /// Excludes messages sent by the user themselves.
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async {
    // Query messages in conversation that are:
    // 1. NOT sent by the user
    // 2. Either have no status record OR status is not 'read'
    final query = selectOnly(messages)
      ..addColumns([messages.id.count()])
      ..where(messages.conversationId.equals(conversationId))
      ..where(messages.senderId.equals(userId).not())
      // Left join with messageStatus to find unread messages
      ..join([
        leftOuterJoin(
          messageStatus,
          messageStatus.messageId.equalsExp(messages.id) &
              messageStatus.userId.equals(userId),
        ),
      ])
      // Filter: no status record OR status != 'read'
      ..where(
        messageStatus.status.isNull() |
            messageStatus.status.equals('read').not(),
      );

    final result = await query.getSingle();
    return result.read(messages.id.count()) ?? 0;
  }

  /// Get all status records for a conversation and user
  ///
  /// Used when syncing delivery status to Firestore
  Future<List<MessageStatusEntity>> getStatusForConversation(
    String conversationId,
    String userId,
  ) async {
    // Join with messages table to filter by conversationId
    final query =
        select(messageStatus).join([
            innerJoin(messages, messages.id.equalsExp(messageStatus.messageId)),
          ])
          ..where(messages.conversationId.equals(conversationId))
          ..where(messageStatus.userId.equals(userId));

    final results = await query.get();
    return results.map((row) => row.readTable(messageStatus)).toList();
  }

  /// Get status for a specific message and user
  Future<MessageStatusEntity?> getStatus({
    required String messageId,
    required String userId,
  }) =>
      (select(messageStatus)..where(
            (ms) => ms.messageId.equals(messageId) & ms.userId.equals(userId),
          ))
          .getSingleOrNull();

  /// Get all status records for a message (for group chats)
  ///
  /// Returns a list of status records, one per participant.
  /// Useful for showing "Read by 2/3" indicators.
  Future<List<MessageStatusEntity>> getStatusForMessage(String messageId) =>
      (select(messageStatus)
            ..where((ms) => ms.messageId.equals(messageId))
            ..orderBy([(ms) => OrderingTerm.asc(ms.userId)]))
          .get();

  /// Watch status updates for a message (reactive stream)
  ///
  /// Returns a stream that emits new values whenever the status changes.
  /// Perfect for real-time status indicator updates in the UI.
  Stream<List<MessageStatusEntity>> watchStatusForMessage(String messageId) =>
      (select(messageStatus)
            ..where((ms) => ms.messageId.equals(messageId))
            ..orderBy([(ms) => OrderingTerm.asc(ms.userId)]))
          .watch();

  /// Get messages with pending status sync for a user
  ///
  /// Returns messages where the user's status needs to be synced to Firestore.
  /// Used by the DeliveryTrackingWorker.
  // For now, return all status records
  // In a production system, we'd add a 'synced' flag to track this
  Future<List<MessageStatusEntity>> getPendingStatusSync() async =>
      select(messageStatus).get();

  /// Count read receipts for a message (group chats)
  ///
  /// Returns how many users have read the message.
  Future<int> getReadCount(String messageId) async {
    final count = messageStatus.userId.count();
    final query = selectOnly(messageStatus)
      ..addColumns([count])
      ..where(messageStatus.messageId.equals(messageId))
      ..where(messageStatus.status.equals('read'));

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get all users who have read a message
  Future<List<String>> getUsersWhoRead(String messageId) async {
    final query = select(messageStatus)
      ..where((ms) => ms.messageId.equals(messageId))
      ..where((ms) => ms.status.equals('read'));

    final results = await query.get();
    return results.map((ms) => ms.userId).toList();
  }

  // ============================================================================
  // Delete Methods
  // ============================================================================

  /// Delete all status records for a message
  ///
  /// Called when a message is deleted.
  Future<void> deleteStatusForMessage(String messageId) async {
    await (delete(
      messageStatus,
    )..where((ms) => ms.messageId.equals(messageId))).go();
  }

  /// Delete status records for a user in a conversation
  ///
  /// Called when a user is removed from a conversation.
  Future<void> deleteStatusForUser({
    required String conversationId,
    required String userId,
  }) async {
    // First get all message IDs in the conversation
    final messagesInConversation = await (select(
      messages,
    )..where((m) => m.conversationId.equals(conversationId))).get();

    // Delete status records for this user for all messages in conversation
    await batch((batch) {
      for (final message in messagesInConversation) {
        batch.delete(
          messageStatus,
          MessageStatusCompanion(
            messageId: Value(message.id),
            userId: Value(userId),
          ),
        );
      }
    });
  }
}
