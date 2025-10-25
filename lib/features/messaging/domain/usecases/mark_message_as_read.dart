/// Use case for marking a message as read by a specific user.
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Use case for marking a message as read for a specific user.
///
/// Updates the message's `readBy` map with the user's timestamp,
/// enabling per-user read receipt tracking in group chats.
///
/// When a user opens a chat and scrolls past a message, this use case
/// records that the message was read at a specific time.
class MarkMessageAsRead {
  /// Creates a new instance of [MarkMessageAsRead].
  MarkMessageAsRead(this._messageRepository);

  /// The message repository for updating read receipts
  final MessageRepository _messageRepository;

  /// Marks a message as read for a specific user.
  ///
  /// Parameters:
  /// - [conversationId]: ID of the conversation containing the message
  /// - [messageId]: ID of the message to mark as read
  /// - [userId]: ID of the user marking the message as read
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

    return _messageRepository.markAsRead(conversationId, messageId, userId);
  }
}
