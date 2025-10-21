/// Use case for sending a message
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Use case for sending a message in a conversation.
///
/// This use case:
/// 1. Validates the message content
/// 2. Creates the message in Firestore
/// 3. Updates the conversation's last message
///
/// Returns the created message or a Failure.
class SendMessage {
  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;

  SendMessage({
    required MessageRepository messageRepository,
    required ConversationRepository conversationRepository,
  })  : _messageRepository = messageRepository,
        _conversationRepository = conversationRepository;

  /// Sends a message to a conversation.
  ///
  /// [conversationId] - ID of the conversation to send the message to
  /// [message] - The message entity to send
  ///
  /// Returns Right(Message) on success, Left(Failure) on error.
  Future<Either<Failure, Message>> call(
    String conversationId,
    Message message,
  ) async {
    // Validate message content
    if (message.text.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message cannot be empty',
          fieldErrors: {'text': 'Message text is required'},
        ),
      );
    }

    // Create message in Firestore
    final result = await _messageRepository.createMessage(
      conversationId,
      message,
    );

    return result.fold(
      (failure) => Left(failure),
      (createdMessage) async {
        // Update conversation's last message
        // (non-critical operation, ignore failures)
        await _conversationRepository.updateLastMessage(
          conversationId,
          createdMessage.text,
          createdMessage.senderId,
          createdMessage.senderName,
          createdMessage.timestamp,
        );

        return Right(createdMessage);
      },
    );
  }
}
