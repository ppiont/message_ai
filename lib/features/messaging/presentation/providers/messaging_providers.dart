/// Riverpod providers for messaging feature
///
/// This file serves as the main entry point for messaging providers.
/// Specific provider categories have been split into focused files:
/// - messaging_core_providers.dart: Core infrastructure (Firestore)
/// - typing_providers.dart: Typing indicators
/// - presence_providers.dart: Presence tracking and FCM
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:message_ai/core/database/app_database.dart'
    show MessageStatusEntity;
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/core/providers/database_provider.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_providers.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/repositories/conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:message_ai/features/messaging/data/services/auto_delivery_marker.dart';
import 'package:message_ai/features/messaging/data/services/message_context_service.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart'
    show Conversation, Participant;
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/add_group_member.dart';
import 'package:message_ai/features/messaging/domain/usecases/create_group.dart';
import 'package:message_ai/features/messaging/domain/usecases/find_or_create_direct_conversation.dart';
import 'package:message_ai/features/messaging/domain/usecases/get_conversation_by_id.dart';
import 'package:message_ai/features/messaging/domain/usecases/leave_group.dart';
import 'package:message_ai/features/messaging/domain/usecases/mark_message_as_delivered.dart';
import 'package:message_ai/features/messaging/domain/usecases/mark_message_as_read.dart';
import 'package:message_ai/features/messaging/domain/usecases/remove_group_member.dart';
import 'package:message_ai/features/messaging/domain/usecases/send_message.dart';
import 'package:message_ai/features/messaging/domain/usecases/update_group_info.dart';
import 'package:message_ai/features/messaging/domain/usecases/watch_conversations.dart';
import 'package:message_ai/features/messaging/domain/usecases/watch_messages.dart';
import 'package:message_ai/features/messaging/presentation/models/message_with_status.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_core_providers.dart';
import 'package:message_ai/features/translation/presentation/providers/language_detection_provider.dart';
import 'package:mutex/mutex.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

// Export focused provider files for external use (Task 8.4)
export 'messaging_core_providers.dart';
export 'presence_providers.dart';
export 'typing_providers.dart';

part 'messaging_providers.g.dart';

// ========== Data Layer Providers ==========

/// Provides the [MessageRemoteDataSource] implementation.
@riverpod
MessageRemoteDataSource messageRemoteDataSource(Ref ref) =>
    MessageRemoteDataSourceImpl(
      firestore: ref.watch(messagingFirestoreProvider),
    );

/// Provides the [MessageLocalDataSource] implementation.
@riverpod
MessageLocalDataSource messageLocalDataSource(Ref ref) {
  final database = ref.watch(databaseProvider);
  return MessageLocalDataSourceImpl(messageDao: database.messageDao);
}

/// Provides the [ConversationRemoteDataSource] implementation.
@riverpod
ConversationRemoteDataSource conversationRemoteDataSource(Ref ref) =>
    ConversationRemoteDataSourceImpl(
      firestore: ref.watch(messagingFirestoreProvider),
    );

/// Provides the [ConversationLocalDataSource] implementation.
@riverpod
ConversationLocalDataSource conversationLocalDataSource(Ref ref) {
  final database = ref.watch(databaseProvider);
  return ConversationLocalDataSourceImpl(
    conversationDao: database.conversationDao,
  );
}

// ========== Repository Providers ==========

/// Provides the [MessageRepository] implementation (offline-first).
@riverpod
MessageRepository messageRepository(Ref ref) => MessageRepositoryImpl(
  remoteDataSource: ref.watch(messageRemoteDataSourceProvider),
  localDataSource: ref.watch(messageLocalDataSourceProvider),
);

/// Provides the [ConversationRepository] implementation (offline-first).
@riverpod
ConversationRepository conversationRepository(Ref ref) =>
    ConversationRepositoryImpl(
      remoteDataSource: ref.watch(conversationRemoteDataSourceProvider),
      localDataSource: ref.watch(conversationLocalDataSourceProvider),
    );

// ========== Message Context Providers ==========

/// Provides Firebase Functions instance for message context analysis
@riverpod
FirebaseFunctions messageContextFunctions(Ref ref) =>
    FirebaseFunctions.instance;

/// Provides the [MessageContextService] for analyzing message cultural context, formality, and idioms
@riverpod
MessageContextService messageContextService(Ref ref) => MessageContextService(
  functions: ref.watch(messageContextFunctionsProvider),
);

// ========== Use Case Providers ==========

/// Provides the [SendMessage] use case with language detection.
///
/// Note: messageQueue removed - WorkManager handles background sync now
/// Note: embeddingGenerator removed - Firestore triggers handle embeddings server-side
@riverpod
SendMessage sendMessageUseCase(Ref ref) => SendMessage(
  messageRepository: ref.watch(messageRepositoryProvider),
  conversationRepository: ref.watch(conversationRepositoryProvider),
  languageDetectionService: ref.watch(languageDetectionServiceProvider),
);

/// Provides the [WatchMessages] use case.
@riverpod
WatchMessages watchMessagesUseCase(Ref ref) =>
    WatchMessages(ref.watch(messageRepositoryProvider));

/// Provides the [MarkMessageAsRead] use case.
@riverpod
MarkMessageAsRead markMessageAsReadUseCase(Ref ref) =>
    MarkMessageAsRead(ref.watch(messageRepositoryProvider));

/// Provides the [MarkMessageAsDelivered] use case.
@riverpod
MarkMessageAsDelivered markMessageAsDeliveredUseCase(Ref ref) =>
    MarkMessageAsDelivered(ref.watch(messageRepositoryProvider));

/// Provides the [FindOrCreateDirectConversation] use case.
@riverpod
FindOrCreateDirectConversation findOrCreateDirectConversationUseCase(Ref ref) =>
    FindOrCreateDirectConversation(ref.watch(conversationRepositoryProvider));

/// Provides the [WatchConversations] use case.
@riverpod
WatchConversations watchConversationsUseCase(Ref ref) =>
    WatchConversations(ref.watch(conversationRepositoryProvider));

/// Provides the [GetConversationById] use case.
@riverpod
GetConversationById getConversationByIdUseCase(Ref ref) =>
    GetConversationById(ref.watch(conversationRepositoryProvider));

// ========== State Providers ==========

/// Stream provider for watching user's conversations in real-time.
///
/// Automatically updates when conversations change in Firestore.
@riverpod
Stream<List<Map<String, dynamic>>> userConversationsStream(
  Ref ref,
  String userId,
) async* {
  final watchUseCase = ref.watch(watchConversationsUseCaseProvider);

  await for (final Either<Failure, List<Conversation>> result in watchUseCase(
    userId: userId,
  )) {
    yield result.fold(
      (Failure failure) => <Map<String, dynamic>>[],
      // Log error but return empty list to keep UI functional
      (List<Conversation> conversations) => conversations
          .map(
            (Conversation conv) => <String, dynamic>{
              'id': conv.documentId,
              'participants': conv.participants
                  .map(
                    (Participant p) => <String, dynamic>{
                      'uid': p.uid,
                      'imageUrl': p.imageUrl,
                      'preferredLanguage': p.preferredLanguage,
                    },
                  )
                  .toList(),
              'lastMessage': conv.lastMessage?.text,
              'lastUpdatedAt': conv.lastUpdatedAt,
              'unreadCount': conv.getUnreadCountForUser(userId),
            },
          )
          .toList(),
    );
  }
}

/// Cached provider for conversation participant IDs.
///
/// Fetches once and caches to avoid repeated fetches during stream rebuilds.
@riverpod
Future<List<String>> conversationParticipantIds(
  Ref ref,
  String conversationId,
) async {
  final getConversationUseCase = ref.watch(getConversationByIdUseCaseProvider);
  final convResult = await getConversationUseCase(conversationId);

  return convResult.fold(
    (failure) => <String>[],
    (conversation) => conversation.participants.map((p) => p.uid).toList(),
  );
}

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.
/// Returns messages with computed status from Firestore.
///
/// Uses real-time listeners for BOTH messages AND status subcollections.
/// When receiver marks delivered/read, sender sees it instantly via WebSocket.
@riverpod
Stream<List<Map<String, dynamic>>> conversationMessagesStream(
  Ref ref,
  String conversationId,
  String currentUserId,
) async* {
  final watchUseCase = ref.watch(watchMessagesUseCaseProvider);
  final userSyncService = ref.watch(userSyncServiceProvider);
  final messageRemoteDataSource = ref.watch(messageRemoteDataSourceProvider);

  // Wait for participant IDs once (cached, won't refetch)
  final participantIdsAsync = ref.watch(
    conversationParticipantIdsProvider(conversationId),
  );

  // Wait for participant IDs to load
  List<String> participantIds;
  if (participantIdsAsync is AsyncData<List<String>>) {
    participantIds = participantIdsAsync.value;
  } else if (participantIdsAsync is AsyncLoading<List<String>>) {
    // Wait for it to load
    participantIds = await ref.read(
      conversationParticipantIdsProvider(conversationId).future,
    );
  } else {
    // Error case
    participantIds = <String>[];
  }

  // Create messages stream (Either<Failure, List<Message>>)
  final messagesEitherStream = watchUseCase(
    conversationId: conversationId,
    currentUserId: currentUserId,
  );

  // Create real-time status stream (scoped to this conversation only)
  final statusStream = messageRemoteDataSource
      .watchConversationStatus(conversationId)
      .map((statusMaps) {
        // Transform list of status maps into Map<messageId, List<statusRecords>>
        final statusByMessage = <String, List<MessageStatusEntity>>{};

        for (final statusMap in statusMaps) {
          final messageId = statusMap['messageId'] as String?;
          if (messageId == null) {
            continue;
          }

          final statusEntity = MessageStatusEntity(
            messageId: messageId,
            userId: statusMap['userId'] as String,
            status: statusMap['status'] as String,
            timestamp: statusMap['timestamp'] != null
                ? (statusMap['timestamp'] as Timestamp).toDate()
                : null,
          );

          statusByMessage.putIfAbsent(messageId, () => []).add(statusEntity);
        }

        return statusByMessage;
      })
      .distinct((prev, next) {
        // Deep equality check: only emit if status actually changed
        if (prev.length != next.length) {
          return false;
        }

        for (final entry in prev.entries) {
          final prevRecords = entry.value;
          final nextRecords = next[entry.key];

          if (nextRecords == null || prevRecords.length != nextRecords.length) {
            return false;
          }

          // Check if all status records are the same
          for (var i = 0; i < prevRecords.length; i++) {
            if (prevRecords[i].userId != nextRecords[i].userId ||
                prevRecords[i].status != nextRecords[i].status) {
              return false;
            }
          }
        }

        return true; // Data is identical, skip emission
      });

  // Combine messages and status streams (participantIds is now constant)
  final combinedStream =
      Rx.combineLatest2<
        Either<Failure, List<Message>>,
        Map<String, List<MessageStatusEntity>>,
        List<Map<String, dynamic>>
      >(
        messagesEitherStream,
        statusStream.startWith({}),
        (messagesEither, statusByMessage) =>
            // Use fold to extract messages or handle failure
            messagesEither.fold(
              (failure) {
                debugPrint('❌ messagesEitherStream error: ${failure.message}');
                return <Map<String, dynamic>>[];
              },
              (List<Message> messages) {
                // Sync all message senders to Drift for offline access (fire-and-forget)
                final allSenderIds = messages
                    .map((Message msg) => msg.senderId)
                    .toSet()
                    .toList();
                if (allSenderIds.isNotEmpty) {
                  allSenderIds.forEach(userSyncService.syncMessageSender);
                }

                // Build MessageWithStatus objects using real-time status data
                return messages.map((Message msg) {
                  // Get status records from real-time stream (not one-time fetch)
                  final statusRecords = msg.senderId == currentUserId
                      ? (statusByMessage[msg.id] ?? <MessageStatusEntity>[])
                      : <MessageStatusEntity>[];

                  // Build MessageWithStatus using factory
                  final messageWithStatus = MessageWithStatus.fromStatusRecords(
                    message: msg,
                    statusRecords: statusRecords,
                    currentUserId: currentUserId,
                    allParticipantIds: participantIds,
                  );

                  // Return as Map for backward compatibility with UI
                  return <String, dynamic>{
                    'id': msg.id,
                    'text': msg.text,
                    'senderId': msg.senderId,
                    'timestamp': msg.timestamp,
                    'status': messageWithStatus.status,
                    'type': msg.type,
                    'detectedLanguage': msg.detectedLanguage,
                    'translations': msg.translations,
                    'culturalHint': msg.culturalHint,
                    'readCount': messageWithStatus.readCount,
                    'deliveredCount': messageWithStatus.deliveredCount,
                    // Total recipients (excluding sender) for group chat status display
                    'totalRecipients': participantIds.isNotEmpty
                        ? participantIds
                              .where((String id) => id != msg.senderId)
                              .length
                        : 0,
                  };
                }).toList();
              },
            ),
      );

  // Emit combined stream results
  await for (final messages in combinedStream) {
    yield messages;
  }
}

/// Auto-marks incoming messages as read when the conversation is open.
///
/// This provider should be watched in the chat page to automatically
/// mark messages as read. It runs as a side effect separate from the
/// message stream to avoid feedback loops.
@Riverpod(keepAlive: true)
class ConversationReadMarker extends _$ConversationReadMarker {
  final _markedAsRead = <String>{};

  /// Mutex to prevent race conditions when marking messages as read (Task 8.3)
  /// Ensures only one markAsRead operation runs at a time
  final _mutex = Mutex();

  @override
  void build(String conversationId, String currentUserId) {
    // Listen to messages and mark as read
    ref.listen(
      conversationMessagesStreamProvider(conversationId, currentUserId),
      (previous, next) {
        next.whenData((messages) {
          // Fire and forget - don't await to avoid blocking the stream
          _markMessagesAsRead(messages, conversationId, currentUserId);
        });
      },
    );
  }

  Future<void> _markMessagesAsRead(
    List<Map<String, dynamic>> messages,
    String conversationId,
    String currentUserId,
  ) async {
    // Use mutex to ensure sequential execution and prevent race conditions (Task 8.3)
    await _mutex.protect(() async {
      final messageRemoteDataSource = ref.read(messageRemoteDataSourceProvider);

      // Find messages to mark (incoming messages not yet marked)
      final messagesToMark = messages
          .where(
            (msg) =>
                msg['senderId'] != currentUserId &&
                !_markedAsRead.contains(msg['id']),
          )
          .toList();

      if (messagesToMark.isEmpty) {
        return;
      }

      debugPrint(
        '📖 Marking ${messagesToMark.length} messages as READ for user ${currentUserId.substring(0, 8)}',
      );

      // Mark all messages as READ in parallel
      final results = await Future.wait(
        messagesToMark.map((msg) async {
          final messageId = msg['id'] as String;
          try {
            await messageRemoteDataSource.markAsRead(
              conversationId,
              messageId,
              currentUserId,
            );
            return (messageId, true);
          } catch (e) {
            debugPrint(
              '❌ Failed to mark ${messageId.substring(0, 8)} as READ: $e',
            );
            return (messageId, false);
          }
        }),
      );

      // Track successfully marked messages
      final successCount = results.where((r) => r.$2).length;
      for (final (messageId, success) in results) {
        if (success) {
          _markedAsRead.add(messageId);
        }
      }

      debugPrint(
        '✅ Successfully marked $successCount/${messagesToMark.length} messages as READ',
      );
    });
  }
}

// ========== Auto Delivery Marker ==========

/// Provides the [AutoDeliveryMarker] service.
///
/// Automatically marks incoming messages as delivered for all conversations.
@Riverpod(keepAlive: true)
AutoDeliveryMarker autoDeliveryMarker(Ref ref) {
  final currentUser = ref.watch(authStateProvider).value;

  if (currentUser == null) {
    throw Exception('User must be authenticated');
  }

  final marker =
      AutoDeliveryMarker(
          conversationRepository: ref.watch(conversationRepositoryProvider),
          messageRepository: ref.watch(messageRepositoryProvider),
          currentUserId: currentUser.uid,
        )
        // Start watching
        ..start();

  // Dispose when provider is disposed
  ref.onDispose(marker.stop);

  return marker;
}

// ========== Message Status Delivery Marker ==========

/// Marks all messages in a conversation as delivered for the current user.
///
/// Simple approach: Writes directly to Firestore subcollections.
/// Sender listens to these subcollections for instant status updates.
///
/// Flow:
/// 1. Get all messages not sent by current user
/// 2. Write "delivered" to Firestore: conversations/{convId}/messages/{msgId}/status/{userId}
/// 3. Sender's listener picks it up instantly
@riverpod
Future<void> markMessagesDelivered(
  Ref ref,
  String conversationId,
  String userId,
) async {
  final messageRemoteDataSource = ref.read(messageRemoteDataSourceProvider);

  debugPrint('[markMessagesDelivered] Fetching messages from Firestore...');

  // Query FIRESTORE directly (not local DB which might be empty!)
  final messages = await messageRemoteDataSource.getMessages(
    conversationId: conversationId,
    limit: 100, // Get recent messages
  );

  debugPrint(
    '[markMessagesDelivered] Found ${messages.length} messages in Firestore',
  );

  // Filter messages not sent by this user
  final otherMessages = messages.where((m) => m.senderId != userId).toList();

  if (otherMessages.isEmpty) {
    debugPrint('[markMessagesDelivered] No messages to mark as delivered');
    return;
  }

  debugPrint(
    '[markMessagesDelivered] Marking ${otherMessages.length} messages as delivered in Firestore',
  );

  // Write directly to Firestore subcollections
  for (final message in otherMessages) {
    try {
      debugPrint(
        '[markMessagesDelivered] Writing status for message ${message.id}',
      );
      await messageRemoteDataSource.markAsDelivered(
        conversationId,
        message.id,
        userId,
      );
      debugPrint('[markMessagesDelivered] ✅ Wrote status for ${message.id}');
    } catch (e) {
      debugPrint('[markMessagesDelivered] ❌ Failed to mark ${message.id}: $e');
    }
  }

  debugPrint(
    '[markMessagesDelivered] ✅ All delivered statuses written to Firestore',
  );
}

// ========== Offline & Sync Providers ==========
//
// NOTE: MessageSyncService and MessageQueue have been removed.
// Background sync is now handled by WorkManager periodic tasks.
// See lib/workers/ for MessageSyncWorker, DeliveryTrackingWorker, ReadReceiptWorker.
//
// ========== Group Use Case Providers ==========
// Note: Group conversations now use the unified ConversationRepository

/// Provides the [CreateGroup] use case.
@riverpod
CreateGroup createGroupUseCase(Ref ref) =>
    CreateGroup(ref.watch(conversationRepositoryProvider));

/// Provides the [AddGroupMember] use case.
@riverpod
AddGroupMember addGroupMemberUseCase(Ref ref) =>
    AddGroupMember(ref.watch(conversationRepositoryProvider));

/// Provides the [RemoveGroupMember] use case.
@riverpod
RemoveGroupMember removeGroupMemberUseCase(Ref ref) =>
    RemoveGroupMember(ref.watch(conversationRepositoryProvider));

/// Provides the [LeaveGroup] use case.
@riverpod
LeaveGroup leaveGroupUseCase(Ref ref) =>
    LeaveGroup(ref.watch(conversationRepositoryProvider));

/// Provides the [UpdateGroupInfo] use case.
@riverpod
UpdateGroupInfo updateGroupInfoUseCase(Ref ref) =>
    UpdateGroupInfo(ref.watch(conversationRepositoryProvider));

// ========== Unified Conversation List Provider ==========

/// Stream provider for watching all conversations (both direct and groups) in real-time.
///
/// Returns all conversations from the unified ConversationRepository,
/// sorted by last update time.
@riverpod
Stream<List<Map<String, dynamic>>> allConversationsStream(
  Ref ref,
  String userId,
) {
  final watchConversationsUseCase = ref.watch(
    watchConversationsUseCaseProvider,
  );
  final userSyncService = ref.watch(userSyncServiceProvider);

  // Watch all conversations (both direct and group)
  final conversationsStream = watchConversationsUseCase(userId: userId);

  return conversationsStream.map((Either<Failure, List<Conversation>> result) {
    // Extract conversations (or empty list on failure)
    final allConversations = result.fold(
      (Failure failure) => <Conversation>[],
      (List<Conversation> conversations) => conversations,
    );

    // Sync all participant users to Drift for offline access (fire-and-forget)
    final allParticipantIds = allConversations
        .expand(
          (Conversation conv) =>
              conv.participants.map((Participant p) => p.uid),
        )
        .toSet()
        .toList();
    if (allParticipantIds.isNotEmpty) {
      // Fire-and-forget: don't await, don't block the stream
      Future<void>.microtask(
        () => userSyncService.syncConversationUsers(allParticipantIds),
      );
    }

    // Map to UI-friendly format
    final mapped =
        allConversations
            .map(
              (Conversation conv) => <String, dynamic>{
                'id': conv.documentId,
                'type': conv.type,
                'groupName': conv.groupName,
                'groupImage': conv.groupImage,
                'participants': conv.participants
                    .map(
                      (Participant p) => <String, dynamic>{
                        'uid': p.uid,
                        'imageUrl': p.imageUrl,
                        'preferredLanguage': p.preferredLanguage,
                      },
                    )
                    .toList(),
                'participantCount': conv.participantIds.length,
                'lastMessage': conv.lastMessage?.text,
                'lastUpdatedAt': conv.lastUpdatedAt,
                'unreadCount': conv.getUnreadCountForUser(userId),
              },
            )
            .toList()
          // Sort by lastUpdatedAt (newest first)
          ..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
            final aTime = a['lastUpdatedAt'] as DateTime;
            final bTime = b['lastUpdatedAt'] as DateTime;
            return bTime.compareTo(aTime);
          });

    return mapped;
  });
}

// ========== Optimized Sorted Conversation List Provider ==========

/// Optimized conversation list that maintains sort order with binary search insertion.
///
/// **Performance Optimization (Task 6.4):**
/// Instead of re-sorting the entire list on every stream update (O(n log n)),
/// this provider uses binary search insertion for incremental updates (O(log n)).
///
/// **Implementation:**
/// - Maintains sorted list state in memory
/// - Diffs incoming stream data to find changed conversations
/// - Uses binary search to find insertion index for changed items
/// - Removes old position and inserts at new position
/// - Debounces rapid updates to prevent excessive list modifications
@Riverpod(keepAlive: true)
class SortedConversationList extends _$SortedConversationList {
  /// Current sorted conversation list
  List<Map<String, dynamic>> _conversations = [];

  /// Debounce timer for rapid updates
  Timer? _debounceTimer;

  /// Debounce delay (200ms is optimal for conversation updates)
  static const Duration _debounceDelay = Duration(milliseconds: 200);

  @override
  List<Map<String, dynamic>> build(String userId) {
    // Listen to conversation stream and apply incremental updates
    ref.listen(
      allConversationsStreamProvider(userId),
      (previous, next) {
        next.whenData((newConversations) {
          // Debounce rapid updates
          _debounceTimer?.cancel();
          _debounceTimer = Timer(_debounceDelay, () {
            _updateConversations(newConversations);
          });
        });
      },
    );

    return _conversations;
  }

  /// Updates conversations using binary search insertion for efficiency.
  ///
  /// Instead of re-sorting entire list, this method:
  /// 1. Diffs old and new conversation lists
  /// 2. For each changed conversation, removes it from old position
  /// 3. Uses binary search to find new insertion index
  /// 4. Inserts at correct position to maintain sort order
  void _updateConversations(List<Map<String, dynamic>> newConversations) {
    if (newConversations.isEmpty) {
      if (_conversations.isNotEmpty) {
        _conversations = [];
        state = _conversations;
      }
      return;
    }

    // If list is empty, initialize with sorted list
    if (_conversations.isEmpty) {
      _conversations = List.from(newConversations)
        ..sort((a, b) {
          final aTime = a['lastUpdatedAt'] as DateTime;
          final bTime = b['lastUpdatedAt'] as DateTime;
          return bTime.compareTo(aTime); // Newest first
        });
      state = _conversations;
      return;
    }

    // Create maps for fast lookup
    final oldMap = {
      for (final conv in _conversations) conv['id'] as String: conv,
    };
    final newMap = {
      for (final conv in newConversations) conv['id'] as String: conv,
    };

    // Find conversations that changed or are new
    final changedIds = <String>[];
    for (final newConv in newConversations) {
      final id = newConv['id'] as String;
      final oldConv = oldMap[id];

      // Check if conversation is new or if lastUpdatedAt changed
      if (oldConv == null ||
          (oldConv['lastUpdatedAt'] as DateTime) !=
              (newConv['lastUpdatedAt'] as DateTime)) {
        changedIds.add(id);
      }
    }

    // Find removed conversations
    final removedIds = oldMap.keys.where((id) => !newMap.containsKey(id)).toList();

    // If more than 50% of list changed, just re-sort (more efficient than many individual updates)
    if (changedIds.length + removedIds.length > _conversations.length * 0.5) {
      _conversations = List.from(newConversations)
        ..sort((a, b) {
          final aTime = a['lastUpdatedAt'] as DateTime;
          final bTime = b['lastUpdatedAt'] as DateTime;
          return bTime.compareTo(aTime);
        });
      state = _conversations;
      return;
    }

    // Apply incremental updates using binary search insertion
    for (final id in removedIds) {
      _conversations.removeWhere((conv) => conv['id'] == id);
    }

    for (final id in changedIds) {
      final newConv = newMap[id]!;

      // Remove old position if exists
      _conversations.removeWhere((conv) => conv['id'] == id);

      // Find insertion index using binary search
      final insertIndex = _binarySearchInsertIndex(
        newConv['lastUpdatedAt'] as DateTime,
      );

      // Insert at correct position
      _conversations.insert(insertIndex, newConv);
    }

    state = _conversations;
  }

  /// Binary search to find insertion index for a conversation with given timestamp.
  ///
  /// Returns the index where a conversation with the given lastUpdatedAt
  /// should be inserted to maintain descending sort order (newest first).
  ///
  /// **Time Complexity:** O(log n)
  int _binarySearchInsertIndex(DateTime lastUpdatedAt) {
    if (_conversations.isEmpty) {
      return 0;
    }

    var left = 0;
    var right = _conversations.length;

    while (left < right) {
      final mid = left + (right - left) ~/ 2;
      final midTime = _conversations[mid]['lastUpdatedAt'] as DateTime;

      // Sort descending (newest first)
      // If new timestamp is after mid, insert before mid
      if (lastUpdatedAt.isAfter(midTime)) {
        right = mid;
      } else {
        left = mid + 1;
      }
    }

    return left;
  }

  /// Manually trigger a full re-sort (useful for testing or recovery)
  void forceResort() {
    _conversations.sort((a, b) {
      final aTime = a['lastUpdatedAt'] as DateTime;
      final bTime = b['lastUpdatedAt'] as DateTime;
      return bTime.compareTo(aTime);
    });
    state = _conversations;
  }
}

// ========== User Discovery Provider ==========

/// Provider for streaming all users from Firestore.
///
/// In a production app, this would be a proper user search/directory feature.
@riverpod
Stream<List<Map<String, dynamic>>> conversationUsersStream(Ref ref) {
  final firestore = ref.watch(messagingFirestoreProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
  }

  return firestore
      .collection('users')
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .where(
              (DocumentSnapshot<Map<String, dynamic>> doc) =>
                  doc.id != currentUser.uid,
            ) // Exclude current user
            .map((DocumentSnapshot<Map<String, dynamic>> doc) {
              final data = doc.data() ?? {};
              return <String, dynamic>{
                'uid': doc.id,
                'name': data['displayName'] as String? ?? '',
                'email': data['email'] as String? ?? '',
                'preferredLanguage':
                    data['preferredLanguage'] as String? ?? 'en',
              };
            })
            .toList(),
      );
}

