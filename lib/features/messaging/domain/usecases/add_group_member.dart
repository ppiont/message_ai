/// Use case for adding a member to a group
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';

/// Use case for adding a new member to an existing group.
///
/// Only group admins should be able to add members.
class AddGroupMember {
  AddGroupMember(this._conversationRepository);
  final ConversationRepository _conversationRepository;

  /// Adds a member to a group.
  ///
  /// [groupId] - ID of the group
  /// [userId] - ID of the user to add
  /// [userName] - Name of the user to add
  /// [preferredLanguage] - Preferred language of the user
  /// [requesterId] - ID of the user making the request (should be admin)
  ///
  /// Returns success or failure.
  Future<Either<Failure, void>> call({
    required String groupId,
    required String userId,
    required String userName,
    required String preferredLanguage,
    required String requesterId,
  }) async {
    // Validate input
    if (groupId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Group ID cannot be empty',
          fieldErrors: {'groupId': 'Group ID is required'},
        ),
      );
    }

    if (userId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID cannot be empty',
          fieldErrors: {'userId': 'User ID is required'},
        ),
      );
    }

    if (userName.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User name cannot be empty',
          fieldErrors: {'userName': 'User name is required'},
        ),
      );
    }

    // Get the group to validate requester is admin
    final groupResult = await _conversationRepository.getConversationById(
      groupId,
    );

    return groupResult.fold(Left.new, (group) async {
      // Check if requester is admin
      if (!(group.adminIds?.contains(requesterId) ?? false)) {
        return const Left(
          UnauthorizedFailure(message: 'Only admins can add members'),
        );
      }

      // Check if user is already a member
      if (group.participantIds.contains(userId)) {
        return const Left(
          ValidationFailure(
            message: 'User is already a member of this group',
            fieldErrors: {'userId': 'User already in group'},
          ),
        );
      }

      // Add the member
      return _conversationRepository.addMember(
        groupId,
        userId,
        userName,
        preferredLanguage,
      );
    });
  }
}
