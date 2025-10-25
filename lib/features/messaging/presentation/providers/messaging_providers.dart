/// Riverpod providers for messaging feature
library;

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
import 'package:message_ai/features/messaging/data/datasources/group_conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/repositories/conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/data/repositories/group_conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:message_ai/features/messaging/data/services/auto_delivery_marker.dart';
import 'package:message_ai/features/messaging/data/services/fcm_service.dart';
import 'package:message_ai/features/messaging/data/services/message_context_service.dart';
import 'package:message_ai/features/messaging/data/services/presence_service.dart'
    show PresenceService, UserPresence;
import 'package:message_ai/features/messaging/data/services/typing_indicator_service.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart'
    show Conversation, Participant;
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/group_conversation_repository.dart';
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
import 'package:message_ai/features/smart_replies/presentation/providers/embedding_providers.dart';
import 'package:message_ai/features/translation/presentation/providers/language_detection_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'messaging_providers.g.dart';

// ========== Data Layer Providers ==========

/// Provides the FirebaseFirestore instance for messaging operations.
@riverpod
FirebaseFirestore messagingFirestore(Ref ref) => FirebaseFirestore.instance;

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
@riverpod
SendMessage sendMessageUseCase(Ref ref) => SendMessage(
  messageRepository: ref.watch(messageRepositoryProvider),
  conversationRepository: ref.watch(conversationRepositoryProvider),
  languageDetectionService: ref.watch(languageDetectionServiceProvider),
  embeddingGenerator: ref.watch(embeddingGeneratorProvider),
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

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.
/// Returns messages with computed status from Firestore.
///
/// Uses real-time listeners for BOTH messages AND status subcollections.
/// When receiver marks delivered/read, sender sees it instantly.
@riverpod
Stream<List<Map<String, dynamic>>> conversationMessagesStream(
  Ref ref,
  String conversationId,
  String currentUserId,
) async* {

  final watchUseCase = ref.watch(watchMessagesUseCaseProvider);
  final userSyncService = ref.watch(userSyncServiceProvider);
  final getConversationUseCase = ref.watch(getConversationByIdUseCaseProvider);
  final groupConversationRepository = ref.watch(
    groupConversationRepositoryProvider,
  );
  final firestore = ref.watch(messagingFirestoreProvider);

  // Track which messages we've already marked as read to prevent infinite loop
  final markedAsRead = <String>{};

  // Get conversation to extract participant IDs for aggregate status computation
  // Try direct conversation first, then group conversation
  var participantIds = <String>[];
  final directConvResult = await getConversationUseCase(conversationId);

  // Check if we got a conversation or need to try group repository
  await directConvResult.fold(
    (failure) async {
      // Direct conversation fetch failed, try group conversation
      debugPrint(
        '📨 conversationMessagesStream: Not a direct conversation, trying group...',
      );
      final groupResult = await groupConversationRepository.getGroupById(
        conversationId,
      );
      groupResult.fold(
        (groupFailure) {
          debugPrint(
            '❌ conversationMessagesStream: Failed to get conversation $conversationId: ${groupFailure.message}',
          );
        },
        (conversation) {
          participantIds = conversation.participants.map((p) => p.uid).toList();
          debugPrint(
            '✅ conversationMessagesStream: Got ${participantIds.length} participants for status computation: $participantIds',
          );
        },
      );
    },
    (conversation) async {
      participantIds = conversation.participants.map((p) => p.uid).toList();
      debugPrint(
        '✅ conversationMessagesStream: Got ${participantIds.length} participants for status computation: $participantIds',
      );
    },
  );

  // Create a stream that watches ALL status subcollections for this conversation
  // This triggers whenever ANY status changes (delivered/read)
  final statusUpdatesStream = firestore
      .collectionGroup('status')
      .snapshots()
      .map((snapshot) => snapshot.docs.length); // Just count changes as trigger

  // Combine messages stream with status updates stream
  // When EITHER changes, rebuild the message list
  await for (final combined in Rx.combineLatest2(
    watchUseCase(
      conversationId: conversationId,
      currentUserId: currentUserId,
    ),
    statusUpdatesStream,
    (Either<Failure, List<Message>> result, int statusCount) => result,
  )) {
    yield await combined.fold(
      (failure) async => [],

      // Log error but return empty list to keep UI functional
      (List<Message> messages) async {
        // Sync all message senders to Drift for offline access
        final allSenderIds = messages
            .map((Message msg) => msg.senderId)
            .toSet()
            .toList();
        if (allSenderIds.isNotEmpty) {
          allSenderIds.forEach(userSyncService.syncMessageSender);
        }

        // WhatsApp-style: When chat is OPEN, mark messages as READ
        // Note: Delivery marking is handled automatically by AutoDeliveryMarker service
        final messageRemoteDataSource = ref.read(messageRemoteDataSourceProvider);

        for (final msg in messages) {
          // Only mark as READ if:
          // 1. Not sent by me
          // 2. Not already marked by us (deduplication)
          // Note: We mark as read when chat is open, AutoDeliveryMarker handles "delivered"
          if (msg.senderId != currentUserId &&
              !markedAsRead.contains(msg.id)) {
            try {
              // Chat is open = mark as READ
              await messageRemoteDataSource.markAsRead(
                conversationId,
                msg.id,
                currentUserId,
              );
              markedAsRead.add(msg.id); // Track to prevent re-marking
            } catch (e) {
              // Silently fail
            }
          }
        }

        // Build MessageWithStatus objects by querying Firestore for current status
        final messagesWithStatus = await Future.wait(
          messages.map((Message msg) async {
            // For messages sent by current user, query Firestore for recipients' status
            List<MessageStatusEntity> statusRecords = [];

            if (msg.senderId == currentUserId) {
              try {
                final messageRemoteDataSource = ref.read(
                  messageRemoteDataSourceProvider,
                );
                final firestoreStatusMaps = await messageRemoteDataSource
                    .getMessageStatus(conversationId, msg.id);

                // Convert Firestore status maps to MessageStatusEntity objects
                statusRecords = firestoreStatusMaps.map((data) {
                  return MessageStatusEntity(
                    messageId: msg.id,
                    userId: data['userId'] as String,
                    status: data['status'] as String,
                    timestamp: data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : null,
                  );
                }).toList();
              } catch (e) {
                debugPrint(
                  '⚠️ Failed to fetch Firestore status for ${msg.id}: $e',
                );
                // Empty list on error
              }
            }

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
                  ? participantIds.where((id) => id != msg.senderId).length
                  : 0,
            };
          }),
        );

        return messagesWithStatus;
      },
    );
  }
}

// ========== Typing Indicator Providers ==========

/// Provides the [TypingIndicatorService] instance.
@riverpod
TypingIndicatorService typingIndicatorService(Ref ref) {
  final service = TypingIndicatorService(
    firestore: ref.watch(messagingFirestoreProvider),
  );

  // Dispose when provider is disposed
  ref.onDispose(service.dispose);

  return service;
}

/// Watches typing users for a specific conversation.
@riverpod
Stream<List<TypingUser>> conversationTypingUsers(
  Ref ref,
  String conversationId,
  String currentUserId,
) {
  final service = ref.watch(typingIndicatorServiceProvider);
  return service.watchTypingUsers(
    conversationId: conversationId,
    currentUserId: currentUserId,
  );
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

  final marker = AutoDeliveryMarker(
    conversationRepository: ref.watch(conversationRepositoryProvider),
    groupConversationRepository: ref.watch(groupConversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    currentUserId: currentUser.uid,
  );

  // Start watching
  marker.start();

  // Dispose when provider is disposed
  ref.onDispose(() {
    marker.stop();
  });

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

  debugPrint('[markMessagesDelivered] Found ${messages.length} messages in Firestore');

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
      debugPrint('[markMessagesDelivered] Writing status for message ${message.id}');
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

  debugPrint('[markMessagesDelivered] ✅ All delivered statuses written to Firestore');
}

// ========== Presence Providers ==========

/// Provides the [PresenceService] instance.
@Riverpod(keepAlive: true)
PresenceService presenceService(Ref ref) {
  final service = PresenceService(
    firestore: ref.watch(messagingFirestoreProvider),
  );

  // Dispose when provider is disposed
  ref.onDispose(service.dispose);

  return service;
}

/// Provides the [FCMService] instance for push notifications.
@Riverpod(keepAlive: true)
FCMService fcmService(Ref ref) {
  final service = FCMService(firestore: ref.watch(messagingFirestoreProvider));

  // Dispose when provider is disposed
  ref.onDispose(service.dispose);

  return service;
}

/// Watches presence status for a specific user.
///
/// Returns a stream of presence data including:
/// - isOnline: true if user is currently online
/// - lastSeen: timestamp of last activity
/// - userName: display name
@riverpod
Stream<Map<String, dynamic>?> userPresence(Ref ref, String userId) {
  final service = ref.watch(presenceServiceProvider);
  return service.watchUserPresence(userId: userId).map((presence) {
    if (presence == null) {
      return null;
    }
    return {
      'isOnline': presence.isOnline,
      'lastSeen': presence.lastSeen,
      'userName': presence.userName,
    };
  });
}

// ========== Offline & Sync Providers ==========
//
// NOTE: MessageSyncService and MessageQueue have been removed.
// Background sync is now handled by WorkManager periodic tasks.
// See lib/workers/ for MessageSyncWorker, DeliveryTrackingWorker, ReadReceiptWorker.
//
// ========== Group Conversation Providers ==========

/// Provides the [GroupConversationRemoteDataSource] implementation.
@riverpod
GroupConversationRemoteDataSource groupConversationRemoteDataSource(Ref ref) =>
    GroupConversationRemoteDataSourceImpl(
      firestore: ref.watch(messagingFirestoreProvider),
    );

/// Provides the [GroupConversationRepository] implementation (offline-first).
@riverpod
GroupConversationRepository groupConversationRepository(Ref ref) =>
    GroupConversationRepositoryImpl(
      remoteDataSource: ref.watch(groupConversationRemoteDataSourceProvider),
      localDataSource: ref.watch(conversationLocalDataSourceProvider),
    );

// ========== Group Use Case Providers ==========

/// Provides the [CreateGroup] use case.
@riverpod
CreateGroup createGroupUseCase(Ref ref) =>
    CreateGroup(ref.watch(groupConversationRepositoryProvider));

/// Provides the [AddGroupMember] use case.
@riverpod
AddGroupMember addGroupMemberUseCase(Ref ref) =>
    AddGroupMember(ref.watch(groupConversationRepositoryProvider));

/// Provides the [RemoveGroupMember] use case.
@riverpod
RemoveGroupMember removeGroupMemberUseCase(Ref ref) =>
    RemoveGroupMember(ref.watch(groupConversationRepositoryProvider));

/// Provides the [LeaveGroup] use case.
@riverpod
LeaveGroup leaveGroupUseCase(Ref ref) =>
    LeaveGroup(ref.watch(groupConversationRepositoryProvider));

/// Provides the [UpdateGroupInfo] use case.
@riverpod
UpdateGroupInfo updateGroupInfoUseCase(Ref ref) =>
    UpdateGroupInfo(ref.watch(groupConversationRepositoryProvider));

// ========== Unified Conversation List Provider ==========

/// Stream provider for watching all conversations (both direct and groups) in real-time.
///
/// Merges direct conversations and group conversations into a single unified list,
/// sorted by last update time.
@riverpod
Stream<List<Map<String, dynamic>>> allConversationsStream(
  Ref ref,
  String userId,
) {
  final watchConversationsUseCase = ref.watch(
    watchConversationsUseCaseProvider,
  );
  final groupConversationRepository = ref.watch(
    groupConversationRepositoryProvider,
  );
  final userSyncService = ref.watch(userSyncServiceProvider);

  // Watch BOTH direct conversations AND group conversations
  final directConversationsStream = watchConversationsUseCase(userId: userId);
  final groupConversationsStream = groupConversationRepository
      .watchGroupsForUser(userId);

  // Combine the two streams using Rx.combineLatest2
  return Rx.combineLatest2<
    Either<Failure, List<Conversation>>,
    Either<Failure, List<Conversation>>,
    List<Map<String, dynamic>>
  >(directConversationsStream, groupConversationsStream, (
    Either<Failure, List<Conversation>> directResult,
    Either<Failure, List<Conversation>> groupResult,
  ) {
    // Extract direct conversations (or empty list on failure)
    final directConversations = directResult.fold(
      (Failure failure) => <Conversation>[],
      (List<Conversation> conversations) => conversations,
    );

    // Extract group conversations (or empty list on failure)
    final groupConversations = groupResult.fold(
      (Failure failure) => <Conversation>[],
      (List<Conversation> conversations) => conversations,
    );

    // Combine both lists
    final allConversations = <Conversation>[
      ...directConversations,
      ...groupConversations,
    ];

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

// ========== Group Presence Provider ==========

/// Provides aggregated online status for a group conversation.
///
/// Returns a map with:
/// - 'onlineCount': Number of members currently online
/// - 'totalCount': Total number of members
/// - 'onlineMembers': List of online member IDs
/// - 'displayText': Human-readable status (e.g., "3/5 online")
@riverpod
Stream<Map<String, dynamic>> groupPresenceStatus(
  Ref ref,
  List<String> participantIds,
) {
  final presenceService = ref.watch(presenceServiceProvider);

  if (participantIds.isEmpty) {
    return Stream<Map<String, dynamic>>.value(<String, dynamic>{
      'onlineCount': 0,
      'totalCount': 0,
      'onlineMembers': <String>[],
      'displayText': 'No members',
    });
  }

  // Watch presence for all participants using Firestore real-time listener
  return presenceService.watchUsersPresence(userIds: participantIds).map((
    Map<String, UserPresence> presenceMap,
  ) {
    final onlineMembers = presenceMap.entries
        .where((MapEntry<String, UserPresence> entry) => entry.value.isOnline)
        .map((MapEntry<String, UserPresence> entry) => entry.key)
        .toList();

    return <String, dynamic>{
      'onlineCount': onlineMembers.length,
      'totalCount': participantIds.length,
      'onlineMembers': onlineMembers,
      'displayText': onlineMembers.isEmpty
          ? 'All offline'
          : '${onlineMembers.length}/${participantIds.length} online',
    };
  });
}
