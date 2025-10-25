/// Use case for updating group information
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/group_conversation_repository.dart';

/// Use case for updating group information (name, image).
///
/// Only group admins should be able to update group info.
class UpdateGroupInfo {
  UpdateGroupInfo(this._groupRepository);
  final GroupConversationRepository _groupRepository;

  /// Updates group information.
  ///
  /// [groupId] - ID of the group
  /// [requesterId] - ID of the user making the request (should be admin)
  /// [groupName] - Optional new group name
  /// [groupImage] - Optional new group image URL
  ///
  /// Returns success or failure.
  Future<Either<Failure, void>> call({
    required String groupId,
    required String requesterId,
    String? groupName,
    String? groupImage,
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

    if (groupName == null && groupImage == null) {
      return const Left(
        ValidationFailure(
          message: 'At least one field must be updated',
          fieldErrors: {'update': 'Nothing to update'},
        ),
      );
    }

    if (groupName != null && groupName.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Group name cannot be empty',
          fieldErrors: {'groupName': 'Group name is required'},
        ),
      );
    }

    // Get the group to validate requester is admin
    final groupResult = await _groupRepository.getGroupById(groupId);

    return groupResult.fold(Left.new, (group) async {
      // Check if requester is admin
      if (!(group.adminIds?.contains(requesterId) ?? false)) {
        return const Left(
          UnauthorizedFailure(
            message: 'Only admins can update group information',
          ),
        );
      }

      // Update the group info
      return _groupRepository.updateGroupInfo(
        groupId: groupId,
        groupName: groupName,
        groupImage: groupImage,
      );
    });
  }
}
