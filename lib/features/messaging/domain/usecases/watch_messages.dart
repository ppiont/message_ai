/// Use case for watching messages in real-time
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Use case for watching messages in a conversation in real-time.
///
/// Returns a stream of messages that updates whenever messages are added,
/// modified, or deleted in the conversation.
class WatchMessages {
  WatchMessages(this._messageRepository);
  final MessageRepository _messageRepository;

  /// Watches messages in a conversation.
  ///
  /// [conversationId] - ID of the conversation to watch
  /// [currentUserId] - ID of the current user (to auto-mark incoming messages as delivered)
  /// [limit] - Maximum number of messages to retrieve (default: 50)
  ///
  /// Returns a stream of Either with Failure or List of Message.
  Stream<Either<Failure, List<Message>>> call({
    required String conversationId,
    required String currentUserId,
    int limit = 50,
  }) {
    if (conversationId.trim().isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'Conversation ID is required',
            fieldErrors: {'conversationId': 'Cannot be empty'},
          ),
        ),
      );
    }

    return _messageRepository.watchMessages(
      conversationId: conversationId,
      currentUserId: currentUserId,
      limit: limit,
    );
  }
}
