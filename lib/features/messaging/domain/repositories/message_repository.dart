/// Repository interface for message operations
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Abstract interface for managing message data.
///
/// This repository handles operations related to messages in conversations,
/// abstracting data sources and error handling.
abstract class MessageRepository {
  /// Creates a new message in a conversation.
  Future<Either<Failure, Message>> createMessage(
    String conversationId,
    Message message,
  );

  /// Retrieves a specific message by ID.
  Future<Either<Failure, Message>> getMessageById(
    String conversationId,
    String messageId,
  );

  /// Retrieves messages for a conversation with pagination.
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  });

  /// Updates an existing message.
  Future<Either<Failure, Message>> updateMessage(
    String conversationId,
    Message message,
  );

  /// Deletes a message.
  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  );

  /// Watches messages in a conversation in real-time.
  Stream<Either<Failure, List<Message>>> watchMessages({
    required String conversationId,
    int limit = 50,
  });

  /// Marks a message as delivered.
  Future<Either<Failure, void>> markAsDelivered(
    String conversationId,
    String messageId,
  );

  /// Marks a message as read.
  Future<Either<Failure, void>> markAsRead(
    String conversationId,
    String messageId,
  );
}
