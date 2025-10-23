import 'package:drift/drift.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/tables/messages_table.dart';

part 'message_dao.g.dart';

/// Data Access Object for Messages table
///
/// Handles all local database operations for messages including:
/// - CRUD operations
/// - Batch operations
/// - Pagination
/// - Sync status tracking
/// - Reactive streams for real-time UI updates
@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get a single message by ID
  Future<MessageEntity?> getMessageById(String messageId) => (select(
    messages,
  )..where((m) => m.id.equals(messageId))).getSingleOrNull();

  /// Get messages for a conversation with pagination
  ///
  /// Orders by timestamp ascending (oldest first) for standard chat UI
  /// Use [limit] and [offset] for pagination
  Future<List<MessageEntity>> getMessagesForConversation(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) =>
      (select(messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)])
            ..limit(limit, offset: offset))
          .get();

  /// Watch messages for a conversation (reactive stream)
  ///
  /// Returns a stream that emits new values whenever messages change
  /// Perfect for real-time chat UI updates
  /// Orders by timestamp ascending (oldest first) for standard chat UI
  Stream<List<MessageEntity>> watchMessagesForConversation(
    String conversationId, {
    int limit = 50,
  }) =>
      (select(messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)])
            ..limit(limit))
          .watch();

  /// Get messages that need to be synced
  ///
  /// Returns messages with syncStatus = 'pending' or 'failed'
  Future<List<MessageEntity>> getUnsyncedMessages() =>
      (select(messages)
            ..where(
              (m) =>
                  m.syncStatus.equals('pending') |
                  m.syncStatus.equals('failed'),
            )
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .get();

  /// Get messages by sync status
  Future<List<MessageEntity>> getMessagesByStatus(String syncStatus) =>
      (select(messages)
            ..where((m) => m.syncStatus.equals(syncStatus))
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)]))
          .get();

  /// Search messages by text content
  Future<List<MessageEntity>> searchMessages(String query) =>
      (select(messages)
            ..where((m) => m.messageText.like('%$query%'))
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)]))
          .get();

  /// Get the last message for a conversation
  Future<MessageEntity?> getLastMessage(String conversationId) =>
      (select(messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(1))
          .getSingleOrNull();

  /// Count messages in a conversation
  Future<int> countMessagesInConversation(String conversationId) async {
    final count = messages.id.count();
    final query = selectOnly(messages)
      ..addColumns([count])
      ..where(messages.conversationId.equals(conversationId));

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Count unread messages (status = 'delivered' for current user)
  Future<int> countUnreadMessages(String conversationId, String userId) async {
    final count = messages.id.count();
    final query = selectOnly(messages)
      ..addColumns([count])
      ..where(
        messages.conversationId.equals(conversationId) &
            messages.senderId.isNotValue(userId) &
            messages.status.equals('delivered'),
      );

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================================
  // Insert/Update/Delete Operations
  // ============================================================================

  /// Insert a new message (optimistic update)
  Future<int> insertMessage(MessagesCompanion message) =>
      into(messages).insert(message);

  /// Insert or update a message
  Future<int> upsertMessage(MessagesCompanion message) =>
      into(messages).insertOnConflictUpdate(message);

  /// Batch insert messages (efficient for initial sync)
  Future<void> insertMessages(List<MessagesCompanion> messageList) async {
    await batch((batch) {
      batch.insertAll(
        messages,
        messageList,
        mode:
            InsertMode.insertOrReplace, // Upsert: insert new or update existing
      );
    });
  }

  /// Update message by ID
  Future<bool> updateMessage(String messageId, MessagesCompanion message) =>
      (update(messages)..where((m) => m.id.equals(messageId)))
          .write(message)
          .then((count) => count > 0);

  /// Update message status (for delivery/read receipts)
  Future<bool> updateMessageStatus(String messageId, String status) =>
      updateMessage(messageId, MessagesCompanion(status: Value(status)));

  /// Update sync status for a message
  Future<bool> updateSyncStatus({
    required String messageId,
    required String syncStatus,
    DateTime? lastSyncAttempt,
    int? retryCount,
  }) => (update(messages)..where((m) => m.id.equals(messageId)))
      .write(
        MessagesCompanion(
          syncStatus: Value(syncStatus),
          lastSyncAttempt: Value(lastSyncAttempt),
          retryCount: Value(retryCount ?? 0),
        ),
      )
      .then((count) => count > 0);

  /// Replace temp ID with real server ID (after successful sync)
  ///
  /// Returns true if the operation was successful
  Future<bool> replaceTempId({
    required String tempId,
    required String realId,
  }) async {
    // Get the temp message
    final tempMessage = await (select(
      messages,
    )..where((m) => m.tempId.equals(tempId))).getSingleOrNull();

    if (tempMessage == null) return false;

    // Delete temp message and insert with real ID
    await transaction(() async {
      await (delete(messages)..where((m) => m.tempId.equals(tempId))).go();

      await into(messages).insert(
        MessagesCompanion.insert(
          id: realId,
          conversationId: tempMessage.conversationId,
          messageText: tempMessage.messageText,
          senderId: tempMessage.senderId,
          senderName: tempMessage.senderName,
          timestamp: tempMessage.timestamp,
          messageType: Value(tempMessage.messageType),
          status: Value(tempMessage.status),
          detectedLanguage: Value(tempMessage.detectedLanguage),
          translations: Value(tempMessage.translations),
          replyTo: Value(tempMessage.replyTo),
          metadata: Value(tempMessage.metadata),
          aiAnalysis: Value(tempMessage.aiAnalysis),
          embedding: Value(tempMessage.embedding),
          syncStatus: const Value('synced'),
          retryCount: Value(tempMessage.retryCount),
          lastSyncAttempt: Value(tempMessage.lastSyncAttempt),
        ),
      );
    });

    return true;
  }

  /// Delete a message
  Future<int> deleteMessage(String messageId) =>
      (delete(messages)..where((m) => m.id.equals(messageId))).go();

  /// Delete all messages in a conversation
  Future<int> deleteMessagesInConversation(String conversationId) => (delete(
    messages,
  )..where((m) => m.conversationId.equals(conversationId))).go();

  /// Delete all messages (use with caution!)
  Future<int> deleteAllMessages() => delete(messages).go();

  // ============================================================================
  // Batch Operations
  // ============================================================================

  /// Batch update message statuses (for read receipts)
  Future<void> batchUpdateStatus({
    required List<String> messageIds,
    required String status,
  }) async {
    await batch((batch) {
      for (final messageId in messageIds) {
        batch.update(
          messages,
          MessagesCompanion(status: Value(status)),
          where: (m) => m.id.equals(messageId),
        );
      }
    });
  }

  /// Batch delete messages
  Future<void> batchDeleteMessages(List<String> messageIds) async {
    await batch((batch) {
      for (final messageId in messageIds) {
        batch.deleteWhere(messages, (m) => m.id.equals(messageId));
      }
    });
  }

  // ============================================================================
  // Special Queries
  // ============================================================================

  /// Get messages that failed to sync and are ready for retry
  ///
  /// Only returns messages where retryCount < maxRetries
  Future<List<MessageEntity>> getFailedMessagesForRetry({int maxRetries = 3}) =>
      (select(messages)
            ..where(
              (m) =>
                  m.syncStatus.equals('failed') &
                  m.retryCount.isSmallerThanValue(maxRetries),
            )
            ..orderBy([(m) => OrderingTerm.asc(m.lastSyncAttempt)]))
          .get();

  /// Get messages for a conversation in a specific time range
  Future<List<MessageEntity>> getMessagesInRange({
    required String conversationId,
    required DateTime startTime,
    required DateTime endTime,
  }) =>
      (select(messages)
            ..where(
              (m) =>
                  m.conversationId.equals(conversationId) &
                  m.timestamp.isBiggerOrEqualValue(startTime) &
                  m.timestamp.isSmallerOrEqualValue(endTime),
            )
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)]))
          .get();

  /// Get messages by sender in a conversation
  Future<List<MessageEntity>> getMessagesBySender({
    required String conversationId,
    required String senderId,
    int limit = 50,
  }) =>
      (select(messages)
            ..where(
              (m) =>
                  m.conversationId.equals(conversationId) &
                  m.senderId.equals(senderId),
            )
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(limit))
          .get();

  /// Get replies to a specific message (threaded conversation)
  Future<List<MessageEntity>> getReplies(String messageId) =>
      (select(messages)
            ..where((m) => m.replyTo.equals(messageId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .get();

  /// Watch replies to a message (reactive)
  Stream<List<MessageEntity>> watchReplies(String messageId) =>
      (select(messages)
            ..where((m) => m.replyTo.equals(messageId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .watch();

  /// Update sender name for all messages from a specific user
  ///
  /// Used when a user changes their display name to propagate
  /// the change to all their cached messages for real-time UI updates
  Future<void> updateSenderNameForUser({
    required String userId,
    required String newSenderName,
  }) => (update(messages)..where((m) => m.senderId.equals(userId))).write(
    MessagesCompanion(senderName: Value(newSenderName)),
  );
}
