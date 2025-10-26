/// Use case for leaving a group
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';

/// Use case for a user to leave a group.
///
/// Any member can leave a group, but the last admin cannot leave
/// without first promoting another member to admin.
class LeaveGroup {
  LeaveGroup(this._conversationRepository);
  final ConversationRepository _conversationRepository;

  /// Leaves a group.
  ///
  /// [groupId] - ID of the group
  /// [userId] - ID of the user leaving the group
  ///
  /// Returns success or failure.
  Future<Either<Failure, void>> call({
    required String groupId,
    required String userId,
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

    // Get the group to validate
    final groupResult = await _conversationRepository.getConversationById(groupId);

    return groupResult.fold(Left.new, (group) async {
      // Check if user is a member
      if (!group.participantIds.contains(userId)) {
        return const Left(
          ValidationFailure(
            message: 'User is not a member of this group',
            fieldErrors: {'userId': 'User not in group'},
          ),
        );
      }

      // Prevent leaving if user is the last admin
      if (group.adminIds?.contains(userId) ?? false) {
        final adminCount = group.adminIds?.length ?? 0;
        if (adminCount <= 1) {
          return const Left(
            ValidationFailure(
              message:
                  'Cannot leave as the last admin. Promote another member first.',
              fieldErrors: {'userId': 'Last admin cannot leave'},
            ),
          );
        }
      }

      // Leave the group (same as removing member)
      return _conversationRepository.removeMember(groupId, userId);
    });
  }
}
