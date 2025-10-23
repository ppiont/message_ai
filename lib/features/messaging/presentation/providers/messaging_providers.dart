/// Riverpod providers for messaging feature
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:message_ai/core/providers/database_provider.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_providers.dart';
import 'package:message_ai/features/cultural_context/data/services/cultural_context_analyzer.dart';
import 'package:message_ai/features/cultural_context/presentation/providers/cultural_context_providers.dart';
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
import 'package:message_ai/features/messaging/data/services/message_queue.dart';
import 'package:message_ai/features/messaging/data/services/message_sync_service.dart';
import 'package:message_ai/features/messaging/data/services/presence_service.dart';
import 'package:message_ai/features/messaging/data/services/typing_indicator_service.dart';
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

// ========== Cultural Context Providers ==========

/// Provides the [CulturalContextAnalyzer] service for background analysis
@riverpod
CulturalContextAnalyzer culturalContextAnalyzer(Ref ref) {
  final analyzer = CulturalContextAnalyzer(
    analyzeCulturalContext: ref.watch(analyzeMessageCulturalContextProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
  );

  // Clear cache when provider is disposed
  ref.onDispose(analyzer.clearCache);

  return analyzer;
}

// ========== Use Case Providers ==========

/// Provides the [SendMessage] use case with language detection.
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

  await for (final result in watchUseCase(userId: userId)) {
    yield result.fold(
      (failure) => [],
      // Log error but return empty list to keep UI functional
      (conversations) => conversations
          .map(
            (conv) => {
              'id': conv.documentId,
              'participants': conv.participants
                  .map(
                    (p) => {
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
/// Automatically analyzes cultural context for received messages.
@riverpod
Stream<List<Map<String, dynamic>>> conversationMessagesStream(
  Ref ref,
  String conversationId,
  String currentUserId,
) async* {
  final watchUseCase = ref.watch(watchMessagesUseCaseProvider);
  final userSyncService = ref.watch(userSyncServiceProvider);
  final culturalAnalyzer = ref.watch(culturalContextAnalyzerProvider);
  final currentUserAsync = ref.watch(currentUserWithFirestoreProvider);

  await for (final result in watchUseCase(
    conversationId: conversationId,
    currentUserId: currentUserId,
  )) {
    yield result.fold(
      (failure) => [],

      // Log error but return empty list to keep UI functional
      (messages) {
        // Sync all message senders to Drift for offline access
        final allSenderIds = messages
            .map((msg) => msg.senderId)
            .toSet()
            .toList();
        if (allSenderIds.isNotEmpty) {
          allSenderIds.forEach(userSyncService.syncMessageSender);
        }

        // Analyze cultural context for received messages (background, fire-and-forget)
        currentUserAsync.whenData((currentUser) {
          if (currentUser != null) {
            for (final msg in messages) {
              // Only analyze received messages without cultural hints
              if (msg.senderId != currentUserId && msg.culturalHint == null) {
                culturalAnalyzer.analyzeMessageInBackground(
                  conversationId: conversationId,
                  message: msg,
                  currentUser: currentUser,
                );
              }
            }
          }
        });

        return messages
            .map(
              (msg) => {
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
/// Automatically marks incoming messages as delivered for all conversations.
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
  final service =
      MessageSyncService(
          messageLocalDataSource: ref.watch(messageLocalDataSourceProvider),
          messageRepository: ref.watch(messageRepositoryProvider),
          conversationLocalDataSource: ref.watch(
            conversationLocalDataSourceProvider,
          ),
          conversationRepository: ref.watch(conversationRepositoryProvider),
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
  final watchConversationsUseCase = ref.watch(
    watchConversationsUseCaseProvider,
  );
  final groupRepository = ref.watch(groupConversationRepositoryProvider);
  final userSyncService = ref.watch(userSyncServiceProvider);

  // Watch direct conversations
  final directStream = watchConversationsUseCase(userId: userId).map(
    (result) => result.fold((failure) => <Map<String, dynamic>>[], (
      conversations,
    ) {
      // Sync all participant users to Drift for offline access (fire-and-forget)
      // Do this asynchronously to avoid blocking the stream
      final allParticipantIds = conversations
          .expand((conv) => conv.participants.map((p) => p.uid))
          .toSet()
          .toList();
      if (allParticipantIds.isNotEmpty) {
        // Fire-and-forget: don't await, don't block the stream
        Future.microtask(
          () => userSyncService.syncConversationUsers(allParticipantIds),
        );
      }

      return conversations
          .map(
            (conv) => <String, dynamic>{
              'id': conv.documentId,
              'type': 'direct',
              'participants': conv.participants
                  .map(
                    (p) => <String, dynamic>{
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
          .toList();
    }),
  );

  // Watch groups
  final groupStream = groupRepository
      .watchGroupsForUser(userId)
      .map(
        (result) => result.fold((failure) => <Map<String, dynamic>>[], (
          groups,
        ) {
          // Sync all participant users to Drift for offline access (fire-and-forget)
          // Do this asynchronously to avoid blocking the stream
          final allParticipantIds = groups
              .expand((group) => group.participants.map((p) => p.uid))
              .toSet()
              .toList();
          if (allParticipantIds.isNotEmpty) {
            // Fire-and-forget: don't await, don't block the stream
            Future.microtask(
              () => userSyncService.syncConversationUsers(allParticipantIds),
            );
          }

          return groups
              .map(
                (group) => <String, dynamic>{
                  'id': group.documentId,
                  'type': 'group',
                  'groupName': group.groupName,
                  'groupImage': group.groupImage,
                  'participants': group.participants
                      .map(
                        (p) => <String, dynamic>{
                          'uid': p.uid,
                          'imageUrl': p.imageUrl,
                          'preferredLanguage': p.preferredLanguage,
                        },
                      )
                      .toList(),
                  'participantCount': group.participantIds.length,
                  'lastMessage': group.lastMessage?.text,
                  'lastUpdatedAt': group.lastUpdatedAt,
                  'unreadCount': group.getUnreadCountForUser(userId),
                },
              )
              .toList();
        }),
      );

  // Merge the two streams using combineLatest2
  // This ensures the combined stream emits whenever EITHER stream emits
  return Rx.combineLatest2(directStream, groupStream, (directConvs, groups) {
    final allConversations = <Map<String, dynamic>>[...directConvs, ...groups]
      // Sort by lastUpdatedAt (newest first)
      ..sort((a, b) {
        final aTime = a['lastUpdatedAt'] as DateTime;
        final bTime = b['lastUpdatedAt'] as DateTime;
        return bTime.compareTo(aTime);
      });

    return allConversations;
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
    return Stream.value([]);
  }

  return firestore
      .collection('users')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where((doc) => doc.id != currentUser.uid) // Exclude current user
            .map((doc) {
              final data = doc.data();
              return {
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
    return Stream.value(<String, dynamic>{
      'onlineCount': 0,
      'totalCount': 0,
      'onlineMembers': <String>[],
      'displayText': 'No members',
    });
  }

  // Watch presence for all participants using Firestore real-time listener
  return presenceService.watchUsersPresence(userIds: participantIds).map((
    presenceMap,
  ) {
    final onlineMembers = presenceMap.entries
        .where((entry) => entry.value.isOnline)
        .map((entry) => entry.key)
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
