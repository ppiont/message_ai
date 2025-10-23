import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/daos/conversation_dao.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';

/// Abstract interface for conversation local data source operations.
///
/// Defines the contract for local database operations on conversations using Drift.
/// Handles CRUD operations, queries, sync status tracking, and batch operations.
abstract class ConversationLocalDataSource {
  // ============================================================================
  // Basic CRUD Operations
  // ============================================================================

  /// Creates a new conversation in local storage.
  ///
  /// Throws [RecordAlreadyExistsException] if conversation with same ID exists.
  Future<Conversation> createConversation(Conversation conversation);

  /// Retrieves a conversation by its document ID.
  ///
  /// Returns null if conversation doesn't exist.
  Future<Conversation?> getConversation(String documentId);

  /// Updates an existing conversation.
  ///
  /// Throws [RecordNotFoundException] if conversation doesn't exist.
  Future<Conversation> updateConversation(Conversation conversation);

  /// Deletes a conversation by document ID.
  ///
  /// Returns true if deleted, false if conversation didn't exist.
  Future<bool> deleteConversation(String documentId);

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Gets all conversations ordered by last update (newest first).
  Future<List<Conversation>> getAllConversations({
    int limit = 50,
    int offset = 0,
  });

  /// Gets conversations for a specific participant/user.
  Future<List<Conversation>> getConversationsByParticipant(
    String userId, {
    int limit = 50,
  });

  /// Gets conversations by type ('direct' or 'group').
  Future<List<Conversation>> getConversationsByType(
    String type, {
    int limit = 50,
  });

  /// Gets direct conversation between two users.
  Future<Conversation?> getDirectConversation(String userId1, String userId2);

  /// Searches conversations by group name.
  Future<List<Conversation>> searchConversationsByName(String query);

  /// Gets active conversations (updated within N days).
  Future<List<Conversation>> getActiveConversations({
    int daysBack = 7,
    int limit = 50,
  });

  // ============================================================================
  // Stream Operations (Reactive)
  // ============================================================================

  /// Watches all conversations (emits on changes).
  Stream<List<Conversation>> watchAllConversations({int limit = 50});

  /// Watches conversations for a specific participant.
  Stream<List<Conversation>> watchConversationsByParticipant(
    String userId, {
    int limit = 50,
  });

  // ============================================================================
  // Special Operations
  // ============================================================================

  /// Updates last message information for a conversation.
  Future<bool> updateLastMessage({
    required String documentId,
    required LastMessage lastMessage,
  });

  /// Increments unread count for all participants except sender.
  Future<bool> incrementUnreadCount({
    required String documentId,
    required String senderId,
    required List<String> participantIds,
  });

  /// Resets unread count to zero for a specific user.
  Future<bool> resetUnreadCount({
    required String documentId,
    required String userId,
  });

  /// Gets total number of conversations.
  Future<int> countConversations();

  /// Gets number of conversations with unread messages for a user.
  Future<int> countUnreadConversations(String userId);

  // ============================================================================
  // Sync Operations
  // ============================================================================

  /// Gets conversations that haven't been synced to remote.
  Future<List<Conversation>> getUnsyncedConversations();

  /// Gets conversations by sync status.
  Future<List<Conversation>> getConversationsByStatus(String syncStatus);

  /// Updates sync status for a conversation.
  Future<bool> updateSyncStatus({
    required String documentId,
    required String syncStatus,
    DateTime? lastSyncAttempt,
    int? retryCount,
  });

  /// Replaces temporary ID with real Firestore ID.
  Future<bool> replaceTempId({required String tempId, required String realId});

  /// Gets conversations that failed to sync and can be retried.
  Future<List<Conversation>> getFailedConversationsForRetry({
    int maxRetries = 3,
  });

  /// Gets conversations updated after a specific timestamp.
  ///
  /// Useful for incremental sync operations.
  Future<List<Conversation>> getConversationsUpdatedAfter(DateTime timestamp);

  // ============================================================================
  // Batch Operations
  // ============================================================================

  /// Inserts multiple conversations efficiently.
  Future<void> insertConversations(List<Conversation> conversations);

  /// Batch updates multiple conversations.
  Future<void> batchUpdateConversations({
    required List<String> documentIds,
    required Map<String, dynamic> updates,
  });

  /// Batch deletes multiple conversations.
  Future<void> batchDeleteConversations(List<String> documentIds);

  // ============================================================================
  // Conflict Resolution
  // ============================================================================

  /// Detects if a conversation has conflicts between local and remote versions.
  Future<bool> hasConflict({
    required Conversation localConversation,
    required Conversation remoteConversation,
  });

  /// Resolves a conflict between local and remote conversation versions.
  ///
  /// Strategies: 'server-wins', 'client-wins', 'merge'
  Future<Conversation> resolveConflict({
    required Conversation localConversation,
    required Conversation remoteConversation,
    String strategy = 'server-wins',
  });

  /// Merges local and remote conversation data intelligently.
  Conversation mergeConversations({
    required Conversation localConversation,
    required Conversation remoteConversation,
  });
}

// ============================================================================
// Implementation
// ============================================================================

/// Implementation of [ConversationLocalDataSource] using Drift.
class ConversationLocalDataSourceImpl implements ConversationLocalDataSource {

  ConversationLocalDataSourceImpl({required ConversationDao conversationDao})
    : _conversationDao = conversationDao;
  final ConversationDao _conversationDao;

  // ============================================================================
  // Helper Methods - Mapping between Entity and Drift
  // ============================================================================

  /// Converts Drift ConversationEntity to domain Conversation
  Conversation _entityToConversation(ConversationEntity entity) => Conversation(
      documentId: entity.documentId,
      type: entity.conversationType,
      participantIds: _deserializeList(entity.participantIds),
      participants: _deserializeParticipants(entity.participants),
      lastMessage: _deserializeLastMessage(entity),
      lastUpdatedAt: entity.lastUpdatedAt,
      initiatedAt: entity.initiatedAt,
      unreadCount: _deserializeUnreadCount(entity.unreadCount),
      translationEnabled: entity.translationEnabled,
      autoDetectLanguage: entity.autoDetectLanguage,
      groupName: entity.groupName,
      groupImage: entity.groupImage,
      adminIds: entity.adminIds != null
          ? _deserializeList(entity.adminIds!)
          : null,
    );

  /// Converts domain Conversation to Drift ConversationsCompanion
  ConversationsCompanion _conversationToCompanion(Conversation conversation) => ConversationsCompanion.insert(
      documentId: conversation.documentId,
      conversationType: conversation.type,
      participantIds: _serializeList(conversation.participantIds),
      participants: _serializeParticipants(conversation.participants),
      lastMessageText: Value(conversation.lastMessage?.text),
      lastMessageSenderId: Value(conversation.lastMessage?.senderId),
      lastMessageTimestamp: Value(conversation.lastMessage?.timestamp),
      lastMessageType: Value(conversation.lastMessage?.type),
      lastMessageTranslations: Value(
        conversation.lastMessage?.translations != null
            ? _serializeTranslations(conversation.lastMessage!.translations!)
            : null,
      ),
      lastUpdatedAt: conversation.lastUpdatedAt,
      initiatedAt: conversation.initiatedAt,
      unreadCount: _serializeUnreadCount(conversation.unreadCount),
      translationEnabled: Value(conversation.translationEnabled),
      autoDetectLanguage: Value(conversation.autoDetectLanguage),
      groupName: Value(conversation.groupName),
      groupImage: Value(conversation.groupImage),
      adminIds: Value(
        conversation.adminIds != null
            ? _serializeList(conversation.adminIds!)
            : null,
      ),
    );

  // ============================================================================
  // Serialization Helpers
  // ============================================================================

  String _serializeList(List<String> list) => json.encode(list);

  List<String> _deserializeList(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  String _serializeParticipants(List<Participant> participants) => json.encode(
        participants
            .map(
            (p) => {
              'uid': p.uid,
              'imageUrl': p.imageUrl,
              'preferredLanguage': p.preferredLanguage,
            },
          )
          .toList(),
    );

  List<Participant> _deserializeParticipants(String jsonString) {
    try {
      final decoded = json.decode(jsonString) as List;
      return decoded
          .map(
            (p) => Participant(
              uid: p['uid'] as String,
              imageUrl: p['imageUrl'] as String?,
              preferredLanguage: p['preferredLanguage'] as String,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  String _serializeUnreadCount(Map<String, int> unreadCount) => json.encode(unreadCount);

  Map<String, int> _deserializeUnreadCount(String jsonString) {
    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (e) {
      return {};
    }
  }

  String? _serializeTranslations(Map<String, String> translations) => json.encode(translations);

  Map<String, String>? _deserializeTranslations(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      return null;
    }
  }

  LastMessage? _deserializeLastMessage(ConversationEntity entity) {
    if (entity.lastMessageText == null) return null;

    return LastMessage(
      text: entity.lastMessageText!,
      senderId: entity.lastMessageSenderId!,
      timestamp: entity.lastMessageTimestamp!,
      type: entity.lastMessageType!,
      translations: _deserializeTranslations(entity.lastMessageTranslations),
    );
  }

  // ============================================================================
  // Basic CRUD Implementation
  // ============================================================================

  @override
  Future<Conversation> createConversation(Conversation conversation) async {
    try {
      // Check if conversation already exists
      final existing = await _conversationDao.getConversationById(
        conversation.documentId,
      );
      if (existing != null) {
        throw RecordAlreadyExistsException(
          recordType: 'Conversation',
          recordId: conversation.documentId,
        );
      }

      // Insert conversation
      await _conversationDao.insertConversation(
        _conversationToCompanion(conversation),
      );

      return conversation;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException(
        message: 'Failed to create conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<Conversation?> getConversation(String documentId) async {
    try {
      final entity = await _conversationDao.getConversationById(documentId);
      return entity != null ? _entityToConversation(entity) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    try {
      // Verify conversation exists
      final existing = await _conversationDao.getConversationById(
        conversation.documentId,
      );
      if (existing == null) {
        throw RecordNotFoundException(
          recordType: 'Conversation',
          recordId: conversation.documentId,
        );
      }

      // Update conversation
      await _conversationDao.updateConversation(
        conversation.documentId,
        _conversationToCompanion(conversation),
      );

      return conversation;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException(
        message: 'Failed to update conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> deleteConversation(String documentId) async {
    try {
      final deletedCount = await _conversationDao.deleteConversation(
        documentId,
      );
      return deletedCount > 0;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to delete conversation',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Query Operations Implementation
  // ============================================================================

  @override
  Future<List<Conversation>> getAllConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final entities = await _conversationDao.getAllConversations(
        limit: limit,
        offset: offset,
      );
      return entities.map(_entityToConversation).cast<Conversation>().toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get all conversations',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Conversation>> getConversationsByParticipant(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final entities = await _conversationDao.getConversationsByParticipant(
        userId,
        limit: limit,
      );
      return entities.map(_entityToConversation).cast<Conversation>().toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get conversations by participant',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Conversation>> getConversationsByType(
    String type, {
    int limit = 50,
  }) async {
    try {
      final entities = await _conversationDao.getConversationsByType(
        type,
        limit: limit,
      );
      return entities.map(_entityToConversation).cast<Conversation>().toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get conversations by type',
        originalError: e,
      );
    }
  }

  @override
  Future<Conversation?> getDirectConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      final entity = await _conversationDao.getDirectConversation(
        userId1,
        userId2,
      );
      return entity != null ? _entityToConversation(entity) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get direct conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Conversation>> searchConversationsByName(String query) async {
    try {
      final entities = await _conversationDao.searchConversationsByName(query);
      return entities.map(_entityToConversation).cast<Conversation>().toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to search conversations',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Conversation>> getActiveConversations({
    int daysBack = 7,
    int limit = 50,
  }) async {
    try {
      final entities = await _conversationDao.getActiveConversations(
        daysBack: daysBack,
        limit: limit,
      );
      return entities.map(_entityToConversation).cast<Conversation>().toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get active conversations',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Stream Operations Implementation
  // ============================================================================

  @override
  Stream<List<Conversation>> watchAllConversations({int limit = 50}) {
    try {
      return _conversationDao
          .watchAllConversations(limit: limit)
          .map(
            (entities) => entities
                .map(_entityToConversation)
                .cast<Conversation>()
                .toList(),
          );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to watch all conversations',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<Conversation>> watchConversationsByParticipant(
    String userId, {
    int limit = 50,
  }) {
    try {
      return _conversationDao
          .watchConversationsByParticipant(userId, limit: limit)
          .map(
            (entities) => entities
                .map(_entityToConversation)
                .cast<Conversation>()
                .toList(),
          );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to watch conversations by participant',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Special Operations Implementation
  // ============================================================================

  @override
  Future<bool> updateLastMessage({
    required String documentId,
    required LastMessage lastMessage,
  }) async {
    try {
      return await _conversationDao.updateLastMessage(
        documentId: documentId,
        messageText: lastMessage.text,
        senderId: lastMessage.senderId,
        timestamp: lastMessage.timestamp,
        messageType: lastMessage.type,
        translations: lastMessage.translations,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to update last message',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> incrementUnreadCount({
    required String documentId,
    required String senderId,
    required List<String> participantIds,
  }) async {
    try {
      return await _conversationDao.incrementUnreadCount(
        documentId: documentId,
        senderId: senderId,
        participantIds: participantIds,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to increment unread count',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> resetUnreadCount({
    required String documentId,
    required String userId,
  }) async {
    try {
      return await _conversationDao.resetUnreadCount(
        documentId: documentId,
        userId: userId,
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to reset unread count',
        originalError: e,
      );
    }
  }

  @override
  Future<int> countConversations() async {
    try {
      return await _conversationDao.countConversations();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to count conversations',
        originalError: e,
      );
    }
  }

  @override
  Future<int> countUnreadConversations(String userId) async {
    try {
      return await _conversationDao.countUnreadConversations(userId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to count unread conversations',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Sync Operations Implementation
  // ============================================================================

  @override
  Future<List<Conversation>> getUnsyncedConversations() async => getConversationsByStatus('pending');

  @override
  Future<List<Conversation>> getConversationsByStatus(String syncStatus) async {
    try {
      // Note: ConversationDao doesn't have a direct getByStatus method
      // We'll use getAllConversations and filter (could optimize later)
      final allConversations = await getAllConversations(limit: 1000);
      // For now, we return all since Drift table doesn't expose syncStatus in query
      // This would need a DAO method addition for full implementation
      return allConversations;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get conversations by status',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> updateSyncStatus({
    required String documentId,
    required String syncStatus,
    DateTime? lastSyncAttempt,
    int? retryCount,
  }) async {
    // Note: Conversations table doesn't have sync fields yet
    // This is a placeholder for future implementation
    // Would need to add syncStatus, lastSyncAttempt, retryCount to table
    return true;
  }

  @override
  Future<bool> replaceTempId({
    required String tempId,
    required String realId,
  }) async {
    try {
      // Get the temporary conversation
      final tempConversation = await getConversation(tempId);
      if (tempConversation == null) return false;

      // Create new conversation with real ID
      final updatedConversation = tempConversation.copyWith(documentId: realId);
      await createConversation(updatedConversation);

      // Delete the temporary one
      await deleteConversation(tempId);

      return true;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to replace temp ID',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Conversation>> getFailedConversationsForRetry({
    int maxRetries = 3,
  }) async {
    try {
      // Similar to getConversationsByStatus, would need DAO support
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get failed conversations for retry',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Conversation>> getConversationsUpdatedAfter(
    DateTime timestamp,
  ) async {
    try {
      final entities = await _conversationDao.getConversationsUpdatedAfter(
        timestamp,
      );
      return entities.map(_entityToConversation).cast<Conversation>().toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get conversations updated after timestamp',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Batch Operations Implementation
  // ============================================================================

  @override
  Future<void> insertConversations(List<Conversation> conversations) async {
    try {
      final companions = conversations
          .map(_conversationToCompanion)
          .cast<ConversationsCompanion>()
          .toList();
      await _conversationDao.insertConversations(companions);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to insert conversations',
        originalError: e,
      );
    }
  }

  @override
  Future<void> batchUpdateConversations({
    required List<String> documentIds,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // Build companion from updates map
      // Note: Currently limited because Conversations table lacks sync fields
      final companion = ConversationsCompanion(
        translationEnabled: updates.containsKey('translationEnabled')
            ? Value(updates['translationEnabled'] as bool)
            : const Value.absent(),
        autoDetectLanguage: updates.containsKey('autoDetectLanguage')
            ? Value(updates['autoDetectLanguage'] as bool)
            : const Value.absent(),
      );

      // Create update map for batch operation
      final updateMap = <String, ConversationsCompanion>{
        for (final id in documentIds) id: companion,
      };

      await _conversationDao.batchUpdateConversations(updateMap);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to batch update conversations',
        originalError: e,
      );
    }
  }

  @override
  Future<void> batchDeleteConversations(List<String> documentIds) async {
    try {
      await _conversationDao.batchDeleteConversations(documentIds);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to batch delete conversations',
        originalError: e,
      );
    }
  }

  // ============================================================================
  // Conflict Resolution Implementation
  // ============================================================================

  @override
  Future<bool> hasConflict({
    required Conversation localConversation,
    required Conversation remoteConversation,
  }) async {
    // Conversations with same ID but different content indicate conflict
    if (localConversation.documentId != remoteConversation.documentId) {
      return false; // Not the same conversation
    }

    // Check if last message differs significantly
    if (localConversation.lastMessage != null &&
        remoteConversation.lastMessage != null) {
      final localMsg = localConversation.lastMessage!;
      final remoteMsg = remoteConversation.lastMessage!;

      // Different message text indicates conflict
      if (localMsg.text != remoteMsg.text) {
        return true;
      }

      // Different timestamps (more than 1 second) indicate conflict
      final timeDiff = localMsg.timestamp.difference(remoteMsg.timestamp);
      if (timeDiff.abs().inSeconds > 1) {
        return true;
      }
    }

    // Check if participant lists differ
    if (localConversation.participantIds.length !=
        remoteConversation.participantIds.length) {
      return true;
    }

    // Check if settings differ
    if (localConversation.translationEnabled !=
            remoteConversation.translationEnabled ||
        localConversation.autoDetectLanguage !=
            remoteConversation.autoDetectLanguage) {
      return true;
    }

    // Check if group metadata differs (for group chats)
    if (localConversation.isGroup && remoteConversation.isGroup) {
      if (localConversation.groupName != remoteConversation.groupName ||
          localConversation.groupImage != remoteConversation.groupImage) {
        return true;
      }
    }

    // No conflicts detected
    return false;
  }

  @override
  Future<Conversation> resolveConflict({
    required Conversation localConversation,
    required Conversation remoteConversation,
    String strategy = 'server-wins',
  }) async {
    Conversation resolvedConversation;

    switch (strategy) {
      case 'server-wins':
        // Remote version takes precedence (default for most sync scenarios)
        resolvedConversation = remoteConversation;

      case 'client-wins':
        // Local version takes precedence (rare, for pending changes)
        resolvedConversation = localConversation;

      case 'merge':
        // Merge both versions intelligently
        resolvedConversation = mergeConversations(
          localConversation: localConversation,
          remoteConversation: remoteConversation,
        );

      default:
        throw ValidationException(
          message: 'Invalid conflict resolution strategy: $strategy',
        );
    }

    // Update the local database with the resolved version
    await updateConversation(resolvedConversation);

    return resolvedConversation;
  }

  @override
  Conversation mergeConversations({
    required Conversation localConversation,
    required Conversation remoteConversation,
  }) {
    // Use remote for core content (server is source of truth)
    // But preserve local additions where possible

    // Use most recent last message
    final LastMessage? mergedLastMessage;
    if (localConversation.lastMessage != null &&
        remoteConversation.lastMessage != null) {
      final localTime = localConversation.lastMessage!.timestamp;
      final remoteTime = remoteConversation.lastMessage!.timestamp;
      mergedLastMessage = localTime.isAfter(remoteTime)
          ? localConversation.lastMessage
          : remoteConversation.lastMessage;
    } else {
      mergedLastMessage =
          remoteConversation.lastMessage ?? localConversation.lastMessage;
    }

    // Merge unread counts (prefer higher counts - safer to over-count than under-count)
    final mergedUnreadCount = <String, int>{};
    final allUserIds = <String>{
      ...localConversation.unreadCount.keys,
      ...remoteConversation.unreadCount.keys,
    };
    for (final userId in allUserIds) {
      final localCount = localConversation.unreadCount[userId] ?? 0;
      final remoteCount = remoteConversation.unreadCount[userId] ?? 0;
      mergedUnreadCount[userId] = localCount > remoteCount
          ? localCount
          : remoteCount;
    }

    // Merge participant lists (union of both)
    final mergedParticipantIds = <String>{
      ...localConversation.participantIds,
      ...remoteConversation.participantIds,
    }.toList();

    // Merge participants (prefer remote, add local if missing)
    final participantMap = <String, Participant>{};
    for (final p in remoteConversation.participants) {
      participantMap[p.uid] = p;
    }
    for (final p in localConversation.participants) {
      participantMap.putIfAbsent(p.uid, () => p);
    }
    final mergedParticipants = participantMap.values.toList();

    // Merge admin IDs if it's a group (union)
    final List<String>? mergedAdminIds;
    if (localConversation.adminIds != null ||
        remoteConversation.adminIds != null) {
      mergedAdminIds = <String>{
        ...?localConversation.adminIds,
        ...?remoteConversation.adminIds,
      }.toList();
    } else {
      mergedAdminIds = null;
    }

    // Use most recent lastUpdatedAt
    final mergedLastUpdatedAt =
        localConversation.lastUpdatedAt.isAfter(
          remoteConversation.lastUpdatedAt,
        )
        ? localConversation.lastUpdatedAt
        : remoteConversation.lastUpdatedAt;

    // Return merged conversation - use remote as base, add local enhancements
    return Conversation(
      documentId: remoteConversation.documentId,
      type: remoteConversation.type,
      participantIds: mergedParticipantIds,
      participants: mergedParticipants,
      lastMessage: mergedLastMessage,
      lastUpdatedAt: mergedLastUpdatedAt,
      initiatedAt: remoteConversation.initiatedAt, // Server timestamp wins
      unreadCount: mergedUnreadCount,
      translationEnabled: remoteConversation.translationEnabled, // Server wins
      autoDetectLanguage: remoteConversation.autoDetectLanguage, // Server wins
      groupName: remoteConversation.groupName, // Server wins
      groupImage: remoteConversation.groupImage, // Server wins
      adminIds: mergedAdminIds,
    );
  }
}
