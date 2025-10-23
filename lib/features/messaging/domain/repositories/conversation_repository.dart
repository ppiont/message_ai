/// Repository interface for conversation operations
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';

/// Abstract interface for managing conversation data.
///
/// This repository handles operations related to conversations,
/// abstracting data sources and error handling.
abstract class ConversationRepository {
  /// Creates a new conversation.
  Future<Either<Failure, Conversation>> createConversation(
    Conversation conversation,
  );

  /// Retrieves a specific conversation by ID.
  Future<Either<Failure, Conversation>> getConversationById(
    String conversationId,
  );

  /// Retrieves conversations for a specific user with pagination.
  Future<Either<Failure, List<Conversation>>> getConversationsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  });

  /// Updates an existing conversation.
  Future<Either<Failure, Conversation>> updateConversation(
    Conversation conversation,
  );

  /// Deletes a conversation.
  Future<Either<Failure, void>> deleteConversation(String conversationId);

  /// Watches conversations for a user in real-time.
  Stream<Either<Failure, List<Conversation>>> watchConversationsForUser(
    String userId, {
    int limit = 50,
  });

  /// Finds an existing 1-to-1 conversation between two users.
  Future<Either<Failure, Conversation?>> findDirectConversation(
    String userId1,
    String userId2,
  );

  /// Updates the last message in a conversation.
  Future<Either<Failure, void>> updateLastMessage(
    String conversationId,
    String messageText,
    String senderId,
    DateTime timestamp,
  );

  /// Updates unread count for a user in a conversation.
  Future<Either<Failure, void>> updateUnreadCount(
    String conversationId,
    String userId,
    int count,
  );
}
