/// Local data source for message operations using Drift
library;

import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/daos/message_dao.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Abstract interface for message local data source operations.
///
/// Defines all operations for storing, retrieving, updating, and syncing
/// messages in the local Drift database. This interface supports offline-first
/// architecture with optimistic updates and sync status tracking.
abstract class MessageLocalDataSource {
  // ============================================================================
  // Basic CRUD Operations
  // ============================================================================

  /// Creates a new message in the local database.
  ///
  /// Used for optimistic updates when sending a message. The message should
  /// have a temp ID and sync status of 'pending'.
  ///
  /// Throws [RecordAlreadyExistsException] if a message with the same ID exists.
  Future<Message> createMessage(String conversationId, Message message);

  /// Retrieves a single message by ID.
  ///
  /// Returns null if the message is not found.
  Future<Message?> getMessage(String messageId);

  /// Updates an existing message.
  ///
  /// The conversationId is required to identify which conversation the message belongs to.
  /// Returns the updated message.
  /// Throws [RecordNotFoundException] if the message doesn't exist.
  Future<Message> updateMessage(String conversationId, Message message);

  /// Deletes a message by ID.
  ///
  /// Returns true if the message was deleted, false if not found.
  Future<bool> deleteMessage(String messageId);

  /// Deletes all messages in a conversation.
  Future<int> deleteMessagesInConversation(String conversationId);

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Retrieves messages for a conversation with pagination.
  ///
  /// Messages are ordered by timestamp (oldest first for standard chat order).
  /// Use [limit] and [offset] for pagination.
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  });

  /// Watches messages for a conversation (reactive stream).
  ///
  /// Returns a stream that emits new values whenever messages change.
  /// Perfect for real-time chat UI updates.
  Stream<List<Message>> watchMessages({
    required String conversationId,
    int limit = 50,
  });

  /// Gets the last message for a conversation.
  ///
  /// Returns null if no messages exist.
  Future<Message?> getLastMessage(String conversationId);

  /// Searches messages by text content.
  Future<List<Message>> searchMessages(String query);

  /// Counts total messages in a conversation.
  Future<int> countMessages(String conversationId);

  /// Counts unread messages for a user in a conversation.
  ///
  /// Unread messages are those with status 'delivered' that were not sent
  /// by the current user.
  Future<int> countUnreadMessages({
    required String conversationId,
    required String userId,
  });

  // ============================================================================
  // Sync Operations
  // ============================================================================

  /// Gets all messages that need to be synced to the server.
  ///
  /// Returns messages with sync status 'pending' or 'failed'.
  Future<List<Message>> getUnsyncedMessages();

  /// Gets messages with a specific sync status.
  Future<List<Message>> getMessagesByStatus(String syncStatus);

  /// Updates the sync status of a message.
  ///
  /// Used to track the sync lifecycle:
  /// - 'pending': Waiting to be synced
  /// - 'synced': Successfully synced with server
  /// - 'failed': Sync attempt failed
  Future<bool> updateSyncStatus({
    required String messageId,
    required String syncStatus,
    DateTime? lastSyncAttempt,
    int? retryCount,
  });

  /// Replaces a temporary ID with the real server ID after successful sync.
  ///
  /// This is crucial for optimistic updates - messages are created with temp IDs
  /// and replaced with real IDs once synced to Firestore.
  Future<bool> replaceTempId({required String tempId, required String realId});

  /// Gets messages that failed to sync and are ready for retry.
  ///
  /// Only returns messages where retry count is below the max retry limit.
  Future<List<Message>> getFailedMessagesForRetry({int maxRetries = 3});

  // ============================================================================
  // Batch Operations
  // ============================================================================

  /// Batch inserts multiple messages for a conversation.
  ///
  /// Efficient for initial sync or bulk operations.
  Future<void> insertMessages(String conversationId, List<Message> messages);

  /// Batch updates message statuses.
  ///
  /// Useful for read receipts when marking multiple messages as read.
  Future<void> batchUpdateStatus({
    required List<String> messageIds,
    required String status,
  });

  /// Batch deletes multiple messages.
  Future<void> batchDeleteMessages(List<String> messageIds);

  // ============================================================================
  // Conflict Resolution
  // ============================================================================

  /// Detects if a message has conflicts between local and remote versions.
  ///
  /// Compares timestamps and content to determine if there's a conflict.
  /// Returns true if local and remote versions differ.
  Future<bool> hasConflict({
    required Message localMessage,
    required Message remoteMessage,
  });

  /// Resolves a conflict between local and remote message versions.
  ///
  /// Supports different resolution strategies:
  /// - 'server-wins': Remote version takes precedence (default for sync)
  /// - 'client-wins': Local version takes precedence (rare, used for user edits)
  /// - 'merge': Combines both versions (for metadata, translations, etc.)
  ///
  /// Returns the resolved message that should be persisted.
  Future<Message> resolveConflict({
    required String conversationId,
    required Message localMessage,
    required Message remoteMessage,
    String strategy = 'server-wins',
  });

  /// Merges metadata and translations from both versions.
  ///
  /// Used when both local and remote have valid updates that don't conflict.
  Message mergeMessages({
    required Message localMessage,
    required Message remoteMessage,
  });

  // ============================================================================
  // Special Operations
  // ============================================================================

  /// Updates message status (for delivery/read receipts).
  Future<bool> updateMessageStatus(String messageId, String status);

  /// Gets messages in a specific time range.
  Future<List<Message>> getMessagesInRange({
    required String conversationId,
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Gets messages by a specific sender.
  Future<List<Message>> getMessagesBySender({
    required String conversationId,
    required String senderId,
    int limit = 50,
  });

  /// Gets replies to a specific message (threaded conversation).
  Future<List<Message>> getReplies(String messageId);

  /// Watches replies to a message (reactive).
  Stream<List<Message>> watchReplies(String messageId);
}

/// Implementation of [MessageLocalDataSource] using Drift database.
///
/// Handles all local database operations for messages, including CRUD operations,
/// sync status tracking, and reactive streams for real-time UI updates.
class MessageLocalDataSourceImpl implements MessageLocalDataSource {
  MessageLocalDataSourceImpl({required MessageDao messageDao})
    : _messageDao = messageDao;
  final MessageDao _messageDao;

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Converts a domain Message entity to a Drift MessagesCompanion for insert/update.
  MessagesCompanion _messageToCompanion(
    String conversationId,
    Message message,
  ) => MessagesCompanion.insert(
    id: message.id,
    conversationId: conversationId,
    messageText: message.text,
    senderId: message.senderId,
    timestamp: message.timestamp,
    messageType: Value(message.type),
    status: Value(message.status),
    detectedLanguage: Value(message.detectedLanguage),
    translations: Value(
      message.translations != null
          ? _serializeTranslations(message.translations!)
          : null,
    ),
    replyTo: Value(message.replyTo),
    metadata: Value(_serializeMetadata(message.metadata)),
    aiAnalysis: Value(
      message.aiAnalysis != null
          ? _serializeAIAnalysis(message.aiAnalysis!)
          : null,
    ),
    culturalHint: Value(message.culturalHint),
    syncStatus: const Value('pending'),
    retryCount: const Value(0),
  );

  /// Converts a Drift MessageEntity to a domain Message entity.
  Message _entityToMessage(MessageEntity entity) => MessageModel(
    id: entity.id,
    text: entity.messageText,
    senderId: entity.senderId,
    timestamp: entity.timestamp,
    type: entity.messageType,
    status: entity.status,
    detectedLanguage: entity.detectedLanguage,
    translations: entity.translations != null
        ? _deserializeTranslations(entity.translations!)
        : null,
    replyTo: entity.replyTo,
    metadata: entity.metadata != null
        ? _deserializeMetadata(entity.metadata!)
        : MessageMetadata.defaultMetadata(),
    aiAnalysis: entity.aiAnalysis != null
        ? _deserializeAIAnalysis(entity.aiAnalysis!)
        : null,
    culturalHint: entity.culturalHint,
  );

  // JSON serialization methods
  String _serializeTranslations(Map<String, String> translations) =>
      jsonEncode(translations);

  Map<String, String> _deserializeTranslations(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  String _serializeMetadata(MessageMetadata metadata) => jsonEncode({
    'edited': metadata.edited,
    'deleted': metadata.deleted,
    'priority': metadata.priority,
    'hasIdioms': metadata.hasIdioms,
  });

  MessageMetadata _deserializeMetadata(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return MessageMetadata(
      edited: decoded['edited'] as bool? ?? false,
      deleted: decoded['deleted'] as bool? ?? false,
      priority: decoded['priority'] as String? ?? 'medium',
      hasIdioms: decoded['hasIdioms'] as bool? ?? false,
    );
  }

  String _serializeAIAnalysis(MessageAIAnalysis analysis) => jsonEncode({
    'priority': analysis.priority,
    'actionItems': analysis.actionItems,
    'sentiment': analysis.sentiment,
  });

  MessageAIAnalysis? _deserializeAIAnalysis(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return MessageAIAnalysis(
        priority: decoded['priority'] as String? ?? 'medium',
        actionItems:
            (decoded['actionItems'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        sentiment: decoded['sentiment'] as String? ?? 'neutral',
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // Basic CRUD Operations Implementation
  // ============================================================================

  @override
  Future<Message> createMessage(String conversationId, Message message) async {
    try {
      final companion = _messageToCompanion(conversationId, message);
      await _messageDao.insertMessage(companion);
      return message;
    } catch (e) {
      // Check for unique constraint violation (primary key already exists)
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('unique') ||
          errorMessage.contains('constraint')) {
        throw RecordAlreadyExistsException(
          recordType: 'Message',
          recordId: message.id,
        );
      }
      throw DatabaseException(
        message: 'Failed to create message',
        originalError: e,
      );
    }
  }

  @override
  Future<Message?> getMessage(String messageId) async {
    try {
      final entity = await _messageDao.getMessageById(messageId);
      return entity != null ? _entityToMessage(entity) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get message',
        originalError: e,
      );
    }
  }

  @override
  Future<Message> updateMessage(String conversationId, Message message) async {
    try {
      final companion = _messageToCompanion(conversationId, message);
      final success = await _messageDao.updateMessage(message.id, companion);

      if (!success) {
        throw RecordNotFoundException(
          recordType: 'Message',
          recordId: message.id,
        );
      }

      return message;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DatabaseException(
        message: 'Failed to update message',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    try {
      final count = await _messageDao.deleteMessage(messageId);
      return count > 0;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to delete message',
        originalError: e,
      );
    }
  }

  @override
  Future<int> deleteMessagesInConversation(String conversationId) async {
    try {
      return await _messageDao.deleteMessagesInConversation(conversationId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to delete messages in conversation',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Query Operations Implementation
  // ============================================================================

  @override
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final entities = await _messageDao.getMessagesForConversation(
        conversationId,
        limit: limit,
        offset: offset,
      );
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get messages',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<Message>> watchMessages({
    required String conversationId,
    int limit = 50,
  }) {
    try {
      return _messageDao
          .watchMessagesForConversation(conversationId, limit: limit)
          .map((entities) => entities.map(_entityToMessage).toList());
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to watch messages',
        originalError: e,
      );
    }
  }

  @override
  Future<Message?> getLastMessage(String conversationId) async {
    try {
      final entity = await _messageDao.getLastMessage(conversationId);
      return entity != null ? _entityToMessage(entity) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get last message',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Message>> searchMessages(String query) async {
    try {
      final entities = await _messageDao.searchMessages(query);
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to search messages',
        originalError: e,
      );
    }
  }

  @override
  Future<int> countMessages(String conversationId) async {
    try {
      return await _messageDao.countMessagesInConversation(conversationId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to count messages',
        originalError: e,
      );
    }
  }

  @override
  Future<int> countUnreadMessages({
    required String conversationId,
    required String userId,
  }) async {
    try {
      return await _messageDao.countUnreadMessages(conversationId, userId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to count unread messages',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Sync Operations Implementation
  // ============================================================================

  @override
  Future<List<Message>> getUnsyncedMessages() async {
    try {
      final entities = await _messageDao.getUnsyncedMessages();
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get unsynced messages',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Message>> getMessagesByStatus(String syncStatus) async {
    try {
      final entities = await _messageDao.getMessagesByStatus(syncStatus);
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get messages by status',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> updateSyncStatus({
    required String messageId,
    required String syncStatus,
    DateTime? lastSyncAttempt,
    int? retryCount,
  }) async {
    try {
      return await _messageDao.updateSyncStatus(
        messageId: messageId,
        syncStatus: syncStatus,
        lastSyncAttempt: lastSyncAttempt,
        retryCount: retryCount,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to update sync status',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> replaceTempId({
    required String tempId,
    required String realId,
  }) async {
    try {
      return await _messageDao.replaceTempId(tempId: tempId, realId: realId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to replace temp ID',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Message>> getFailedMessagesForRetry({int maxRetries = 3}) async {
    try {
      final entities = await _messageDao.getFailedMessagesForRetry(
        maxRetries: maxRetries,
      );
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get failed messages for retry',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Batch Operations Implementation
  // ============================================================================

  @override
  Future<void> insertMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    try {
      final companions = messages
          .map((msg) => _messageToCompanion(conversationId, msg))
          .toList();
      await _messageDao.insertMessages(companions);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to batch insert messages',
        originalError: e,
      );
    }
  }

  @override
  Future<void> batchUpdateStatus({
    required List<String> messageIds,
    required String status,
  }) async {
    try {
      await _messageDao.batchUpdateStatus(
        messageIds: messageIds,
        status: status,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to batch update status',
        originalError: e,
      );
    }
  }

  @override
  Future<void> batchDeleteMessages(List<String> messageIds) async {
    try {
      await _messageDao.batchDeleteMessages(messageIds);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to batch delete messages',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Special Operations Implementation
  // ============================================================================

  @override
  Future<bool> updateMessageStatus(String messageId, String status) async {
    try {
      return await _messageDao.updateMessageStatus(messageId, status);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to update message status',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Message>> getMessagesInRange({
    required String conversationId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final entities = await _messageDao.getMessagesInRange(
        conversationId: conversationId,
        startTime: startTime,
        endTime: endTime,
      );
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get messages in range',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Message>> getMessagesBySender({
    required String conversationId,
    required String senderId,
    int limit = 50,
  }) async {
    try {
      final entities = await _messageDao.getMessagesBySender(
        conversationId: conversationId,
        senderId: senderId,
        limit: limit,
      );
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get messages by sender',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Message>> getReplies(String messageId) async {
    try {
      final entities = await _messageDao.getReplies(messageId);
      return entities.map(_entityToMessage).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get replies',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<Message>> watchReplies(String messageId) {
    try {
      return _messageDao
          .watchReplies(messageId)
          .map((entities) => entities.map(_entityToMessage).toList());
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to watch replies',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Conflict Resolution Implementation
  // ============================================================================

  @override
  Future<bool> hasConflict({
    required Message localMessage,
    required Message remoteMessage,
  }) async {
    // Messages with same ID but different content or timestamps indicate conflict
    if (localMessage.id != remoteMessage.id) {
      return false; // Not the same message
    }

    // Check if content differs
    if (localMessage.text != remoteMessage.text) {
      return true;
    }

    // Check if status differs (but allow progression: sent -> delivered -> read)
    if (localMessage.status != remoteMessage.status) {
      // Status progression is not a conflict
      final statusProgression = ['sent', 'delivered', 'read'];
      final localIndex = statusProgression.indexOf(localMessage.status);
      final remoteIndex = statusProgression.indexOf(remoteMessage.status);

      // If remote is further along, it's progression, not conflict
      if (remoteIndex > localIndex) {
        return false;
      }

      // Otherwise it's a conflict
      return true;
    }

    // Check if timestamps are significantly different (more than 1 second)
    final timeDiff = localMessage.timestamp.difference(remoteMessage.timestamp);
    if (timeDiff.abs().inSeconds > 1) {
      return true;
    }

    // Check metadata differences
    if (localMessage.metadata.edited != remoteMessage.metadata.edited ||
        localMessage.metadata.deleted != remoteMessage.metadata.deleted) {
      return true;
    }

    // No conflicts detected
    return false;
  }

  @override
  Future<Message> resolveConflict({
    required String conversationId,
    required Message localMessage,
    required Message remoteMessage,
    String strategy = 'server-wins',
  }) async {
    Message resolvedMessage;

    switch (strategy) {
      case 'server-wins':
        // Remote version takes precedence (default for most sync scenarios)
        resolvedMessage = remoteMessage;

      case 'client-wins':
        // Local version takes precedence (used for user edits that haven't synced yet)
        resolvedMessage = localMessage;

      case 'merge':
        // Merge both versions intelligently
        resolvedMessage = mergeMessages(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

      default:
        throw ValidationException(
          message: 'Invalid conflict resolution strategy: $strategy',
        );
    }

    // Update the local database with the resolved version
    await updateMessage(conversationId, resolvedMessage);

    return resolvedMessage;
  }

  @override
  Message mergeMessages({
    required Message localMessage,
    required Message remoteMessage,
  }) {
    // Use remote for core content (server is source of truth)
    // But preserve local additions where possible

    // Merge translations - combine both maps
    final mergedTranslations = <String, String>{
      ...?remoteMessage.translations,
      ...?localMessage.translations,
    };

    // Merge AI analysis - prefer remote but keep local action items if newer
    MessageAIAnalysis? mergedAnalysis;
    if (remoteMessage.aiAnalysis != null || localMessage.aiAnalysis != null) {
      final remoteAnalysis = remoteMessage.aiAnalysis;
      final localAnalysis = localMessage.aiAnalysis;

      if (remoteAnalysis != null && localAnalysis != null) {
        // Combine action items from both
        final allActionItems = <String>{
          ...remoteAnalysis.actionItems,
          ...localAnalysis.actionItems,
        }.toList();

        mergedAnalysis = MessageAIAnalysis(
          priority: remoteAnalysis.priority, // Server priority wins
          actionItems: allActionItems,
          sentiment: remoteAnalysis.sentiment, // Server sentiment wins
        );
      } else {
        mergedAnalysis = remoteAnalysis ?? localAnalysis;
      }
    }

    // Use most advanced status (progression: sent -> delivered -> read)
    final statusProgression = ['sent', 'delivered', 'read'];
    final localStatusIndex = statusProgression.indexOf(localMessage.status);
    final remoteStatusIndex = statusProgression.indexOf(remoteMessage.status);
    final mergedStatus = localStatusIndex > remoteStatusIndex
        ? localMessage.status
        : remoteMessage.status;

    // Merge metadata - OR boolean flags, prefer higher priority
    final mergedMetadata = MessageMetadata(
      edited: localMessage.metadata.edited || remoteMessage.metadata.edited,
      deleted: localMessage.metadata.deleted || remoteMessage.metadata.deleted,
      priority: _higherPriority(
        localMessage.metadata.priority,
        remoteMessage.metadata.priority,
      ),
      hasIdioms:
          localMessage.metadata.hasIdioms || remoteMessage.metadata.hasIdioms,
    );

    // Return merged message - use remote as base, add local enhancements
    return Message(
      id: remoteMessage.id,
      text: remoteMessage.text, // Server text is source of truth
      senderId: remoteMessage.senderId,
      timestamp: remoteMessage.timestamp, // Server timestamp wins
      type: remoteMessage.type,
      status: mergedStatus,
      detectedLanguage: remoteMessage.detectedLanguage,
      translations: mergedTranslations.isNotEmpty ? mergedTranslations : null,
      replyTo: remoteMessage.replyTo,
      metadata: mergedMetadata,
      aiAnalysis: mergedAnalysis,
    );
  }

  /// Helper to determine higher priority between two priority strings.
  String _higherPriority(String priority1, String priority2) {
    const priorityLevels = {'low': 1, 'medium': 2, 'high': 3, 'urgent': 4};

    final level1 = priorityLevels[priority1] ?? 2;
    final level2 = priorityLevels[priority2] ?? 2;

    if (level1 >= level2) {
      return priority1;
    } else {
      return priority2;
    }
  }
}
