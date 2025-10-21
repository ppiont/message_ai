/// Riverpod providers for messaging feature
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/repositories/conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/find_or_create_direct_conversation.dart';
import 'package:message_ai/features/messaging/domain/usecases/get_conversation_by_id.dart';
import 'package:message_ai/features/messaging/domain/usecases/mark_message_as_read.dart';
import 'package:message_ai/features/messaging/domain/usecases/send_message.dart';
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

/// Provides the [ConversationRemoteDataSource] implementation.
@riverpod
ConversationRemoteDataSource conversationRemoteDataSource(Ref ref) {
  return ConversationRemoteDataSourceImpl(
    firestore: ref.watch(messagingFirestoreProvider),
  );
}

// ========== Repository Providers ==========

/// Provides the [MessageRepository] implementation.
@riverpod
MessageRepository messageRepository(Ref ref) {
  return MessageRepositoryImpl(
    remoteDataSource: ref.watch(messageRemoteDataSourceProvider),
  );
}

/// Provides the [ConversationRepository] implementation.
@riverpod
ConversationRepository conversationRepository(Ref ref) {
  return ConversationRepositoryImpl(
    remoteDataSource: ref.watch(conversationRemoteDataSourceProvider),
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

/// Provides the [FindOrCreateDirectConversation] use case.
@riverpod
FindOrCreateDirectConversation findOrCreateDirectConversationUseCase(Ref ref) {
  return FindOrCreateDirectConversation(ref.watch(conversationRepositoryProvider));
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
        return conversations.map((conv) => {
          'id': conv.documentId,
          'participants': conv.participants,
          'lastMessage': conv.lastMessage,
          'lastUpdatedAt': conv.lastUpdatedAt,
          'unreadCount': conv.getUnreadCountForUser(userId),
        }).toList();
      },
    );
  }
}

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.
@riverpod
Stream<List<Map<String, dynamic>>> conversationMessagesStream(
  Ref ref,
  String conversationId,
) async* {
  final watchUseCase = ref.watch(watchMessagesUseCaseProvider);

  await for (final result in watchUseCase(conversationId: conversationId)) {
    yield result.fold(
      (failure) {
        // Log error but return empty list to keep UI functional
        return [];
      },
      (messages) {
        return messages.map((msg) => {
          'id': msg.id,
          'text': msg.text,
          'senderId': msg.senderId,
          'senderName': msg.senderName,
          'timestamp': msg.timestamp,
          'status': msg.status,
        }).toList();
      },
    );
  }
}
