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
// Will be added as we create use cases

// ========== State Providers ==========
// Will be added for UI state management (e.g., active conversation, typing indicators)
