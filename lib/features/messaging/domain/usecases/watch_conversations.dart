/// Use case for watching conversations in real-time
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';

/// Use case for watching a user's conversations in real-time.
///
/// Returns a stream of conversations that updates whenever conversations
/// are created, modified, or deleted.
class WatchConversations {
  final ConversationRepository _conversationRepository;

  WatchConversations(this._conversationRepository);

  /// Watches conversations for a user.
  ///
  /// [userId] - ID of the user whose conversations to watch
  /// [limit] - Maximum number of conversations to retrieve (default: 50)
  ///
  /// Returns a stream of Either with Failure or List of Conversation.
  Stream<Either<Failure, List<Conversation>>> call({
    required String userId,
    int limit = 50,
  }) {
    if (userId.trim().isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'User ID is required',
            fieldErrors: {'userId': 'Cannot be empty'},
          ),
        ),
      );
    }

    return _conversationRepository.watchConversationsForUser(
      userId,
      limit: limit,
    );
  }
}
