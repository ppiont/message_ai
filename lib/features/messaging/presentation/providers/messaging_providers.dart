/// Riverpod providers for messaging feature
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
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
import 'package:message_ai/features/messaging/data/services/message_queue.dart';
import 'package:message_ai/features/messaging/data/services/message_sync_service.dart';
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
import 'package:message_ai/features/smart_replies/presentation/providers/embedding_providers.dart';
import 'package:message_ai/features/translation/presentation/providers/language_detection_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
FirebaseFunctions messageContextFunctions(Ref ref) => FirebaseFunctions.instance;

/// Provides the [MessageContextService] for analyzing message cultural context, formality, and idioms
@riverpod
MessageContextService messageContextService(Ref ref) =>
    MessageContextService(functions: ref.watch(messageContextFunctionsProvider));

// ========== Use Case Providers ==========

/// Provides the [SendMessage] use case with language detection.
@riverpod
SendMessage sendMessageUseCase(Ref ref) => SendMessage(
  messageRepository: ref.watch(messageRepositoryProvider),
  conversationRepository: ref.watch(conversationRepositoryProvider),
  languageDetectionService: ref.watch(languageDetectionServiceProvider),
  embeddingGenerator: ref.watch(embeddingGeneratorProvider),
  messageQueue: ref.watch(messageQueueProvider),
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
  final watchUseCase =
      ref.watch(watchConversationsUseCaseProvider);

  await for (final Either<Failure, List<Conversation>> result
      in watchUseCase(userId: userId)) {
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
/// Automatically marks incoming messages as delivered.
@riverpod
Stream<List<Map<String, dynamic>>> conversationMessagesStream(
  Ref ref,
  String conversationId,
  String currentUserId,
) async* {
  final watchUseCase = ref.watch(watchMessagesUseCaseProvider);
  final userSyncService = ref.watch(userSyncServiceProvider);

  await for (final result in watchUseCase(
    conversationId: conversationId,
    currentUserId: currentUserId,
  )) {
    yield result.fold(
      (failure) => [],

      // Log error but return empty list to keep UI functional
      (List<Message> messages) {
        // Sync all message senders to Drift for offline access
        final allSenderIds = messages
            .map((Message msg) => msg.senderId)
            .toSet()
            .toList();
        if (allSenderIds.isNotEmpty) {
          allSenderIds.forEach(userSyncService.syncMessageSender);
        }

        return messages
            .map(
              (Message msg) => <String, dynamic>{
                'id': msg.id,
                'text': msg.text,
                'senderId': msg.senderId,
                'timestamp': msg.timestamp,
                'status': msg.status,
                'type': msg.type,
                'detectedLanguage': msg.detectedLanguage,
                'translations': msg.translations,
                'culturalHint': msg.culturalHint,
              },
            )
            .toList();
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
/// Automatically marks incoming messages as delivered for all conversations
/// (both direct and group conversations).
@Riverpod(keepAlive: true)
AutoDeliveryMarker? autoDeliveryMarker(Ref ref) {
  final currentUser = ref.watch(authStateProvider).value;

  // Return null if user is not authenticated (e.g., on logout)
  if (currentUser == null) {
    return null;
  }

  final marker =
      AutoDeliveryMarker(
          conversationRepository: ref.watch(conversationRepositoryProvider),
          groupConversationRepository: ref.watch(groupConversationRepositoryProvider),
          messageRepository: ref.watch(messageRepositoryProvider),
          currentUserId: currentUser.uid,
        )
        // Start watching
        // ignore: cascade_invocations
        ..start();

  // Dispose when provider is disposed
  ref.onDispose(marker.stop);

  return marker;
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

/// Provides the [MessageSyncService] instance.
///
/// Handles background synchronization between local and remote storage.
@Riverpod(keepAlive: true)
MessageSyncService messageSyncService(Ref ref) {
  final database = ref.watch(databaseProvider);
  final service =
      MessageSyncService(
          messageLocalDataSource: ref.watch(messageLocalDataSourceProvider),
          messageRepository: ref.watch(messageRepositoryProvider),
          conversationLocalDataSource: ref.watch(
            conversationLocalDataSourceProvider,
          ),
          conversationRepository: ref.watch(conversationRepositoryProvider),
          messageDao: database.messageDao,
          connectivity: Connectivity(),
        )
        // Start monitoring connectivity and syncing
        // ignore: cascade_invocations
        ..start();

  // Dispose when provider is disposed
  ref.onDispose(service.stop);

  return service;
}

/// Provides the [MessageQueue] instance.
///
/// Handles optimistic UI updates and background message processing.
@Riverpod(keepAlive: true)
MessageQueue messageQueue(Ref ref) {
  final queue =
      MessageQueue(
          localDataSource: ref.watch(messageLocalDataSourceProvider),
          syncService: ref.watch(messageSyncServiceProvider),
        )
        // Start processing queue
        // ignore: cascade_invocations
        ..start();

  // Dispose when provider is disposed
  ref.onDispose(queue.stop);

  return queue;
}

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
  final watchConversationsUseCase =
      ref.watch(watchConversationsUseCaseProvider);
  final userSyncService = ref.watch(userSyncServiceProvider);

  // Watch all conversations (direct and groups)
  // Note: watchConversationsUseCase returns all conversation types
  return watchConversationsUseCase(userId: userId).map(
    (Either<Failure, List<Conversation>> result) =>
        result.fold((Failure failure) => <Map<String, dynamic>>[], (
      List<Conversation> conversations,
    ) {
      // Sync all participant users to Drift for offline access (fire-and-forget)
      // Do this asynchronously to avoid blocking the stream
      final allParticipantIds = conversations
          .expand((Conversation conv) =>
              conv.participants.map((Participant p) => p.uid))
          .toSet()
          .toList();
      if (allParticipantIds.isNotEmpty) {
        // Fire-and-forget: don't await, don't block the stream
        Future<void>.microtask(
          () => userSyncService.syncConversationUsers(allParticipantIds),
        );
      }

      final mapped = conversations
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
    }),
  );
}

// ========== User Discovery Provider ==========

/// Provider for streaming all users from Firestore.
///
/// In a production app, this would be a proper user search/directory feature.
@riverpod
Stream<List<Map<String, dynamic>>> conversationUsersStream(Ref ref) {
  final firestore =
      ref.watch(messagingFirestoreProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
  }

  return firestore
      .collection('users')
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs
                .where((DocumentSnapshot<Map<String, dynamic>> doc) =>
                    doc.id != currentUser.uid) // Exclude current user
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
  final presenceService =
      ref.watch(presenceServiceProvider);

  if (participantIds.isEmpty) {
    return Stream<Map<String, dynamic>>.value(<String, dynamic>{
      'onlineCount': 0,
      'totalCount': 0,
      'onlineMembers': <String>[],
      'displayText': 'No members',
    });
  }

  // Watch presence for all participants using Firestore real-time listener
  return presenceService
      .watchUsersPresence(userIds: participantIds)
      .map((Map<String, UserPresence> presenceMap) {
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
