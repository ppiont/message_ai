/// Use case for removing a member from a group
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/group_conversation_repository.dart';

/// Use case for removing a member from an existing group.
///
/// Only group admins should be able to remove members.
class RemoveGroupMember {
  final GroupConversationRepository _groupRepository;

  RemoveGroupMember(this._groupRepository);

  /// Removes a member from a group.
  ///
  /// [groupId] - ID of the group
  /// [userId] - ID of the user to remove
  /// [requesterId] - ID of the user making the request (should be admin)
  ///
  /// Returns success or failure.
  Future<Either<Failure, void>> call({
    required String groupId,
    required String userId,
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

    // Get the group to validate requester is admin
    final groupResult = await _groupRepository.getGroupById(groupId);

    return groupResult.fold((failure) => Left(failure), (group) async {
      // Check if requester is admin
      if (!(group.adminIds?.contains(requesterId) ?? false)) {
        return const Left(
          UnauthorizedFailure(message: 'Only admins can remove members'),
        );
      }

      // Check if user is a member
      if (!group.participantIds.contains(userId)) {
        return const Left(
          ValidationFailure(
            message: 'User is not a member of this group',
            fieldErrors: {'userId': 'User not in group'},
          ),
        );
      }

      // Prevent removing the last admin
      if (group.adminIds?.contains(userId) ?? false) {
        final adminCount = group.adminIds?.length ?? 0;
        if (adminCount <= 1) {
          return const Left(
            ValidationFailure(
              message: 'Cannot remove the last admin',
              fieldErrors: {'userId': 'Group must have at least one admin'},
            ),
          );
        }
      }

      // Remove the member
      return _groupRepository.removeMember(groupId, userId);
    });
  }
}
