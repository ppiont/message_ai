/// Use case for finding or creating a direct conversation between two users
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:uuid/uuid.dart';

/// Use case for finding an existing direct conversation or creating a new one.
///
/// This is the primary way to initiate a 1-to-1 chat. It ensures that
/// only one direct conversation exists between any two users.
class FindOrCreateDirectConversation {
  FindOrCreateDirectConversation(this._conversationRepository)
    : _uuid = const Uuid();
  final ConversationRepository _conversationRepository;
  final Uuid _uuid;

  /// Finds or creates a direct conversation between two users.
  ///
  /// [userId1] - First user's ID
  /// [userId2] - Second user's ID
  /// [user1Participant] - Participant details for user 1
  /// [user2Participant] - Participant details for user 2
  ///
  /// Returns the existing or newly created conversation.
  Future<Either<Failure, Conversation>> call({
    required String userId1,
    required String userId2,
    required Participant user1Participant,
    required Participant user2Participant,
  }) async {
    // Validate input
    if (userId1.trim().isEmpty || userId2.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User IDs cannot be empty',
          fieldErrors: {'userId': 'Both user IDs are required'},
        ),
      );
    }

    if (userId1 == userId2) {
      return const Left(
        ValidationFailure(
          message: 'Cannot create conversation with yourself',
          fieldErrors: {'userId': 'User IDs must be different'},
        ),
      );
    }

    // Try to find existing conversation
    final findResult = await _conversationRepository.findDirectConversation(
      userId1,
      userId2,
    );

    return findResult.fold(Left.new, (existingConversation) async {
      // If conversation exists, return it
      if (existingConversation != null) {
        return Right(existingConversation);
      }

      // Otherwise, create new conversation
      final now = DateTime.now();
      final newConversation = Conversation(
        documentId: _uuid.v4(),
        type: 'direct',
        participantIds: [userId1, userId2],
        participants: [user1Participant, user2Participant],
        lastUpdatedAt: now,
        initiatedAt: now,
        unreadCount: {userId1: 0, userId2: 0},
        translationEnabled: false,
        autoDetectLanguage: false,
      );

      return _conversationRepository.createConversation(newConversation);
    });
  }
}
