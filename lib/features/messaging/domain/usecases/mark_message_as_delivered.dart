import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Use case for marking a message as delivered.
///
/// This is called when a message arrives at the recipient's device
/// but before they've actually opened the chat to read it.
class MarkMessageAsDelivered {

  MarkMessageAsDelivered(this._repository);
  final MessageRepository _repository;

  /// Marks the specified message as delivered
  ///
  /// [conversationId] - The conversation containing the message
  /// [messageId] - The ID of the message to mark as delivered
  Future<Either<Failure, void>> call(
    String conversationId,
    String messageId,
  ) async => _repository.markAsDelivered(conversationId, messageId);
}
