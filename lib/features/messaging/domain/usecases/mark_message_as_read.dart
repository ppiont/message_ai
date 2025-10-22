/// Use case for marking a message as read
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Use case for marking a message as read.
///
/// This updates the message's status to 'read' and can trigger
/// read receipt notifications.
class MarkMessageAsRead {

  MarkMessageAsRead(this._messageRepository);
  final MessageRepository _messageRepository;

  /// Marks a message as read.
  ///
  /// [conversationId] - ID of the conversation containing the message
  /// [messageId] - ID of the message to mark as read
  ///
  /// Returns Right(void) on success, Left(Failure) on error.
  Future<Either<Failure, void>> call(
    String conversationId,
    String messageId,
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

    return _messageRepository.markAsRead(conversationId, messageId);
  }
}
