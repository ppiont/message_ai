import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Use case for marking a message as delivered for a specific user.
///
/// This is called when a message arrives at the recipient's device
/// but before they've actually opened the chat to read it.
/// Enables per-user delivery tracking in group chats.
class MarkMessageAsDelivered {

  MarkMessageAsDelivered(this._repository);
  final MessageRepository _repository;

  /// Marks the specified message as delivered for a specific user.
  ///
  /// [conversationId] - The conversation containing the message
  /// [messageId] - The ID of the message to mark as delivered
  /// [userId] - The ID of the user receiving the message
  Future<Either<Failure, void>> call(
    String conversationId,
    String messageId,
    String userId,
  ) async {
    if (conversationId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Conversation ID is required',
          fieldErrors: {'conversationId': 'Cannot be empty'},
        ),
      );
    }

    if (messageId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message ID is required',
          fieldErrors: {'messageId': 'Cannot be empty'},
        ),
      );
    }

    if (userId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          fieldErrors: {'userId': 'Cannot be empty'},
        ),
      );
    }

    return _repository.markAsDelivered(conversationId, messageId, userId);
  }
}
