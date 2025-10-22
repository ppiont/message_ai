/// Riverpod providers for messaging feature
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:message_ai/core/providers/database_providers.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/repositories/conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:message_ai/features/messaging/data/services/auto_delivery_marker.dart';
import 'package:message_ai/features/messaging/data/services/message_queue.dart';
import 'package:message_ai/features/messaging/data/services/message_sync_service.dart';
import 'package:message_ai/features/messaging/data/services/presence_service.dart';
import 'package:message_ai/features/messaging/data/services/typing_indicator_service.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/messaging/data/datasources/group_conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/repositories/group_conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/domain/repositories/group_conversation_repository.dart';
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
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messaging_providers.g.dart';

// ========== Data Layer Providers ==========

/// Provides the FirebaseFirestore instance for messaging operations.
@riverpod
FirebaseFirestore messagingFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// Provides the [MessageRemoteDataSource] implementation.
@riverpod
MessageRemoteDataSource messageRemoteDataSource(Ref ref) {
  return MessageRemoteDataSourceImpl(
    firestore: ref.watch(messagingFirestoreProvider),
  );
}

/// Provides the [MessageLocalDataSource] implementation.
@riverpod
MessageLocalDataSource messageLocalDataSource(Ref ref) {
  final database = ref.watch(databaseProvider);
  return MessageLocalDataSourceImpl(messageDao: database.messageDao);
}

/// Provides the [ConversationRemoteDataSource] implementation.
@riverpod
ConversationRemoteDataSource conversationRemoteDataSource(Ref ref) {
  return ConversationRemoteDataSourceImpl(
    firestore: ref.watch(messagingFirestoreProvider),
  );
}

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
MessageRepository messageRepository(Ref ref) {
  return MessageRepositoryImpl(
    remoteDataSource: ref.watch(messageRemoteDataSourceProvider),
    localDataSource: ref.watch(messageLocalDataSourceProvider),
  );
}

/// Provides the [ConversationRepository] implementation (offline-first).
@riverpod
ConversationRepository conversationRepository(Ref ref) {
  return ConversationRepositoryImpl(
    remoteDataSource: ref.watch(conversationRemoteDataSourceProvider),
    localDataSource: ref.watch(conversationLocalDataSourceProvider),
  );
}

// ========== Use Case Providers ==========

/// Provides the [SendMessage] use case.
@riverpod
SendMessage sendMessageUseCase(Ref ref) {
  return SendMessage(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
  );
}

/// Provides the [WatchMessages] use case.
@riverpod
WatchMessages watchMessagesUseCase(Ref ref) {
  return WatchMessages(ref.watch(messageRepositoryProvider));
}

/// Provides the [MarkMessageAsRead] use case.
@riverpod
MarkMessageAsRead markMessageAsReadUseCase(Ref ref) {
  return MarkMessageAsRead(ref.watch(messageRepositoryProvider));
}

/// Provides the [MarkMessageAsDelivered] use case.
@riverpod
MarkMessageAsDelivered markMessageAsDeliveredUseCase(Ref ref) {
  return MarkMessageAsDelivered(ref.watch(messageRepositoryProvider));
}

/// Provides the [FindOrCreateDirectConversation] use case.
@riverpod
FindOrCreateDirectConversation findOrCreateDirectConversationUseCase(Ref ref) {
  return FindOrCreateDirectConversation(
    ref.watch(conversationRepositoryProvider),
  );
}

/// Provides the [WatchConversations] use case.
@riverpod
WatchConversations watchConversationsUseCase(Ref ref) {
  return WatchConversations(ref.watch(conversationRepositoryProvider));
}

/// Provides the [GetConversationById] use case.
@riverpod
GetConversationById getConversationByIdUseCase(Ref ref) {
  return GetConversationById(ref.watch(conversationRepositoryProvider));
}

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
      (failure) {
        // Log error but return empty list to keep UI functional
        return [];
      },
      (conversations) {
        return conversations.map((conv) {
          return {
            'id': conv.documentId,
            'participants': conv.participants
                .map(
                  (p) => {
                    'uid': p.uid,
                    'name': p.name,
                    'imageUrl': p.imageUrl,
                    'preferredLanguage': p.preferredLanguage,
                  },
                )
                .toList(),
            'lastMessage': conv.lastMessage?.text,
            'lastUpdatedAt': conv.lastUpdatedAt,
            'unreadCount': conv.getUnreadCountForUser(userId),
          };
        }).toList();
      },
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

  await for (final result in watchUseCase(
    conversationId: conversationId,
    currentUserId: currentUserId,
  )) {
    yield result.fold(
      (failure) {
        // Log error but return empty list to keep UI functional
        return [];
      },
      (messages) {
        return messages
            .map(
              (msg) => {
                'id': msg.id,
                'text': msg.text,
                'senderId': msg.senderId,
                'senderName': msg.senderName,
                'timestamp': msg.timestamp,
                'status': msg.status,
                'type': msg.type,
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
  ref.onDispose(() {
    service.dispose();
  });

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

// ========== Presence Providers ==========

/// Provides the [PresenceService] instance.
@Riverpod(keepAlive: true)
PresenceService presenceService(Ref ref) {
  final service = PresenceService(
    firestore: ref.watch(messagingFirestoreProvider),
  );

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

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
    if (presence == null) return null;
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
  final service = MessageSyncService(
    messageLocalDataSource: ref.watch(messageLocalDataSourceProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationLocalDataSource: ref.watch(conversationLocalDataSourceProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    connectivity: Connectivity(),
  );

  // Start monitoring connectivity and syncing
  service.start();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.stop();
  });

  return service;
}

/// Provides the [MessageQueue] instance.
///
/// Handles optimistic UI updates and background message processing.
@Riverpod(keepAlive: true)
MessageQueue messageQueue(Ref ref) {
  final queue = MessageQueue(
    localDataSource: ref.watch(messageLocalDataSourceProvider),
    syncService: ref.watch(messageSyncServiceProvider),
  );

  // Start processing queue
  queue.start();

  // Dispose when provider is disposed
  ref.onDispose(() {
    queue.stop();
  });

  return queue;
}

// ========== Group Conversation Providers ==========

/// Provides the [GroupConversationRemoteDataSource] implementation.
@riverpod
GroupConversationRemoteDataSource groupConversationRemoteDataSource(Ref ref) {
  return GroupConversationRemoteDataSourceImpl(
    firestore: ref.watch(messagingFirestoreProvider),
  );
}

/// Provides the [GroupConversationRepository] implementation (offline-first).
@riverpod
GroupConversationRepository groupConversationRepository(Ref ref) {
  return GroupConversationRepositoryImpl(
    remoteDataSource: ref.watch(groupConversationRemoteDataSourceProvider),
    localDataSource: ref.watch(conversationLocalDataSourceProvider),
  );
}

// ========== Group Use Case Providers ==========

/// Provides the [CreateGroup] use case.
@riverpod
CreateGroup createGroupUseCase(Ref ref) {
  return CreateGroup(ref.watch(groupConversationRepositoryProvider));
}

/// Provides the [AddGroupMember] use case.
@riverpod
AddGroupMember addGroupMemberUseCase(Ref ref) {
  return AddGroupMember(ref.watch(groupConversationRepositoryProvider));
}

/// Provides the [RemoveGroupMember] use case.
@riverpod
RemoveGroupMember removeGroupMemberUseCase(Ref ref) {
  return RemoveGroupMember(ref.watch(groupConversationRepositoryProvider));
}

/// Provides the [LeaveGroup] use case.
@riverpod
LeaveGroup leaveGroupUseCase(Ref ref) {
  return LeaveGroup(ref.watch(groupConversationRepositoryProvider));
}

/// Provides the [UpdateGroupInfo] use case.
@riverpod
UpdateGroupInfo updateGroupInfoUseCase(Ref ref) {
  return UpdateGroupInfo(ref.watch(groupConversationRepositoryProvider));
}

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

  // Watch direct conversations
  final directStream = watchConversationsUseCase(userId: userId).map((result) {
    return result.fold(
      (failure) => <Map<String, dynamic>>[],
      (conversations) => conversations.map((conv) {
        return <String, dynamic>{
          'id': conv.documentId,
          'type': 'direct',
          'participants': conv.participants
              .map(
                (p) => <String, dynamic>{
                  'uid': p.uid,
                  'name': p.name,
                  'imageUrl': p.imageUrl,
                  'preferredLanguage': p.preferredLanguage,
                },
              )
              .toList(),
          'lastMessage': conv.lastMessage?.text,
          'lastUpdatedAt': conv.lastUpdatedAt,
          'unreadCount': conv.getUnreadCountForUser(userId),
        };
      }).toList(),
    );
  });

  // Watch groups
  final groupStream = groupRepository.watchGroupsForUser(userId).map((result) {
    return result.fold(
      (failure) => <Map<String, dynamic>>[],
      (groups) => groups.map((group) {
        return <String, dynamic>{
          'id': group.documentId,
          'type': 'group',
          'groupName': group.groupName,
          'groupImage': group.groupImage,
          'participants': group.participants
              .map(
                (p) => <String, dynamic>{
                  'uid': p.uid,
                  'name': p.name,
                  'imageUrl': p.imageUrl,
                  'preferredLanguage': p.preferredLanguage,
                },
              )
              .toList(),
          'participantCount': group.participantIds.length,
          'lastMessage': group.lastMessage?.text,
          'lastUpdatedAt': group.lastUpdatedAt,
          'unreadCount': group.getUnreadCountForUser(userId),
        };
      }).toList(),
    );
  });

  // Merge the two streams and sort by lastUpdatedAt
  return directStream.asyncExpand((directConvs) async* {
    await for (final groups in groupStream) {
      final allConversations = <Map<String, dynamic>>[
        ...directConvs,
        ...groups,
      ];

      // Sort by lastUpdatedAt (newest first)
      allConversations.sort((a, b) {
        final aTime = a['lastUpdatedAt'] as DateTime;
        final bTime = b['lastUpdatedAt'] as DateTime;
        return bTime.compareTo(aTime);
      });

      yield allConversations;
    }
  });
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
  String groupId,
) async* {
  final groupRepository = ref.watch(groupConversationRepositoryProvider);

  // Get the group to know who the members are
  final groupResult = await groupRepository.getGroupById(groupId);

  yield* groupResult.fold(
    (failure) => Stream.value({
      'onlineCount': 0,
      'totalCount': 0,
      'onlineMembers': <String>[],
      'displayText': 'Unknown',
    }),
    (group) async* {
      final presenceService = ref.watch(presenceServiceProvider);
      final participantIds = group.participantIds;

      // Combine all presence streams
      await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
        // Poll presence for all members
        final onlineMembers = <String>[];

        for (final userId in participantIds) {
          final presenceStream = presenceService.watchUserPresence(
            userId: userId,
          );
          await for (final presence in presenceStream.take(1)) {
            if (presence != null && presence.isOnline) {
              onlineMembers.add(userId);
            }
            break;
          }
        }

        yield {
          'onlineCount': onlineMembers.length,
          'totalCount': participantIds.length,
          'onlineMembers': onlineMembers,
          'displayText': onlineMembers.isEmpty
              ? 'All offline'
              : '${onlineMembers.length}/${participantIds.length} online',
        };
      }
    },
  );
}
