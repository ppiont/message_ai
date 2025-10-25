/// Use case for getting a conversation by ID
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';

/// Use case for retrieving a specific conversation by its ID.
class GetConversationById {
  GetConversationById(this._conversationRepository);
  final ConversationRepository _conversationRepository;

  /// Gets a conversation by ID.
  ///
  /// [conversationId] - ID of the conversation to retrieve
  ///
  /// Returns Right(Conversation) on success, Left(Failure) on error.
  Future<Either<Failure, Conversation>> call(String conversationId) async {
    if (conversationId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Conversation ID is required',
          fieldErrors: {'conversationId': 'Cannot be empty'},
        ),
      );
    }

    return _conversationRepository.getConversationById(conversationId);
  }
}
