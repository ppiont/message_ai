/// Use case for marking a message as delivered to a specific user.
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Use case for marking a message as delivered to a specific user.
///
/// Called when a message arrives at the recipient's device but before
/// they've opened the chat to read it. Updates the message's [deliveredTo]
/// map, enabling per-user delivery tracking in group chats.
///
/// This is typically triggered by:
/// - Push notification delivery confirmation
/// - App opening with unread messages
/// - Message stream subscription activation
class MarkMessageAsDelivered {
  /// Creates a new instance of [MarkMessageAsDelivered].
  MarkMessageAsDelivered(this._repository);

  /// The message repository for updating delivery receipts
  final MessageRepository _repository;

  /// Marks a message as delivered to a specific user.
  ///
  /// Parameters:
  /// - [conversationId]: The conversation containing the message
  /// - [messageId]: The ID of the message to mark as delivered
  /// - [userId]: The ID of the user receiving the message
  ///
  /// Returns [Right] with void on success, [Left] with [Failure] on error.
  /// Performs parameter validation before delegating to the repository.
  Future<Either<Failure, void>> call(
    final String conversationId,
    final String messageId,
    final String userId,
  ) async {
    // Validate conversation ID
    if (conversationId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Conversation ID is required',
          fieldErrors: <String, String>{'conversationId': 'Cannot be empty'},
        ),
      );
    }

    // Validate message ID
    if (messageId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message ID is required',
          fieldErrors: <String, String>{'messageId': 'Cannot be empty'},
        ),
      );
    }

    // Validate user ID
    if (userId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          fieldErrors: <String, String>{'userId': 'Cannot be empty'},
        ),
      );
    }

    return _repository.markAsDelivered(conversationId, messageId, userId);
  }
}
